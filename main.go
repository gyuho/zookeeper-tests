package main

import (
	"flag"
	"fmt"
	mrand "math/rand"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/samuel/go-zookeeper/zk"
)

func main() {
	endpointsPt := flag.String("endpoints", "localhost:2181", "endpoints (currently supports only 1 endpoint)")
	clientsNPt := flag.Int("clients", 100, "number of concurrent clients")
	writesNPt := flag.Int("writes", 1000, "number of write requests")
	keySizePt := flag.Int("key-size", 8, "key size")
	valSizePt := flag.Int("val-size", 256, "value size")
	flag.Parse()

	eps := []string{*endpointsPt}
	clientsN := *clientsNPt
	writesN := *writesNPt
	keySize := *keySizePt
	valSize := *valSizePt

	var wg sync.WaitGroup

	pairs := make(chan zkOp, clientsN) // buffer == maximum concurrent clients size
	wg.Add(1)
	go func() {
		defer func() {
			wg.Done()
			close(pairs)
		}()

		val := randBytes(valSize)
		for i := 0; i < writesN; i++ {
			pairs <- zkOp{Key: "/" + sequentialKey(keySize, i), Value: val}
		}
	}()

	rs := make(chan result, writesN)
	points := make([]result, 0, writesN)
	donec, errm := make(chan struct{}), make(map[string]int)
	total, min, max := time.Duration(0), time.Duration(0), time.Duration(0)
	go func() {
		defer close(donec)
		cnt := 0
		for r := range rs {
			points = append(points, r)
			if cnt%500 == 0 {
				fmt.Println("success", cnt, "/", writesN)
			}
			if r.errStr != "" {
				errm[r.errStr]++
			}
			total += r.duration
			if min == time.Duration(0) {
				min = r.duration
			}
			if min > r.duration {
				min = r.duration
			}
			if max < r.duration {
				max = r.duration
			}
			cnt++
		}
	}()

	conns := mustCreateConnsZk(eps, clientsN)
	for i := range conns {
		wg.Add(1)
		go func(i int, conn *zk.Conn) {
			defer wg.Done()
			for pair := range pairs {
				reqNow := time.Now()
				_, err := conn.Create(pair.Key, pair.Value, zkCreateFlags, zkCreateAcl)
				reqTook := time.Since(reqNow)
				errStr := ""
				if err != nil {
					errStr = err.Error()
				}
				rs <- result{errStr: errStr, duration: reqTook, ts: reqNow.Unix()}
			}
		}(i, conns[i])
	}
	defer func() {
		for _, conn := range conns {
			conn.Close()
		}
	}()
	wg.Wait()
	close(rs)
	<-donec

	fmt.Println("Total clients:", clientsN)
	fmt.Println("Total requests:", writesN)
	fmt.Println("Average:", total/time.Duration(writesN))
	fmt.Println("Min:", min)
	fmt.Println("Max:", max)

	if len(errm) == 0 {
		fmt.Println("No error!")
	} else {
		fmt.Println("Error:")
		for k, v := range errm {
			fmt.Println(k, v)
		}
	}
	sort.Sort(results(points))

	f, err := openToOverwrite("result.csv")
	if err != nil {
		panic(err)
	}
	defer f.Close()
	for _, p := range points {
		f.WriteString(fmt.Sprintf("%d, %f\n", p.ts, p.duration.Seconds()))
	}

	// for i := 0; i < 10; i++ {
	// 	resp, _, err := conns[0].Get(sequentialKey(keySize, i), nil)
	// 	if err != nil {
	// 		panic(err)
	// 	}
	// 	rs := *resp
	// 	fmt.Printf("Get response: %q %q\n", rs.Key, string(rs.Value))
	// }
}

var (
	zkCreateFlags = int32(0)
	zkCreateAcl   = zk.WorldACL(zk.PermAll)
)

type zkOp struct {
	Key   string
	Value []byte
}

var dialTotal int

func mustCreateConnsZk(endpoints []string, total int) []*zk.Conn {
	zks := make([]*zk.Conn, total)
	for i := range zks {
		endpoint := endpoints[dialTotal%len(endpoints)]
		dialTotal++
		conn, _, err := zk.Connect([]string{endpoint}, time.Second)
		if err != nil {
			panic(err)
		}
		zks[i] = conn
	}
	return zks
}

// sequentialKey returns '00012' when size is 5 and num is 12.
func sequentialKey(size, num int) string {
	txt := fmt.Sprintf("%d", num)
	if len(txt) > size {
		return txt
	}
	delta := size - len(txt)
	return strings.Repeat("0", delta) + txt
}

func randBytes(bytesN int) []byte {
	const (
		letterBytes   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		letterIdxBits = 6                    // 6 bits to represent a letter index
		letterIdxMask = 1<<letterIdxBits - 1 // All 1-bits, as many as letterIdxBits
		letterIdxMax  = 63 / letterIdxBits   // # of letter indices fitting in 63 bits
	)
	src := mrand.NewSource(time.Now().UnixNano())
	b := make([]byte, bytesN)
	for i, cache, remain := bytesN-1, src.Int63(), letterIdxMax; i >= 0; {
		if remain == 0 {
			cache, remain = src.Int63(), letterIdxMax
		}
		if idx := int(cache & letterIdxMask); idx < len(letterBytes) {
			b[i] = letterBytes[idx]
			i--
		}
		cache >>= letterIdxBits
		remain--
	}
	return b
}

type result struct {
	errStr   string
	duration time.Duration
	ts       int64
}

type results []result

func (s results) Len() int {
	return len(s)
}

func (s results) Less(i, j int) bool {
	return s[i].ts < s[j].ts
}

func (s results) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

func openToOverwrite(fpath string) (*os.File, error) {
	f, err := os.OpenFile(fpath, os.O_RDWR|os.O_TRUNC|os.O_CREATE, 0600)
	if err != nil {
		return nil, err
	}
	return f, nil
}
