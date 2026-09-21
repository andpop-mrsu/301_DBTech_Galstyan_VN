package main
import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	file, err := os.Open("ratings.csv")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Scan()

	counts := make(map[int]int)

	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Split(line, ",")

		userID, _ := strconv.Atoi(parts[0])
		counts[userID]++
	}

	minID := 0
	maxID := 0
	minCount := 0
	maxCount := 0

	first := true

	for id, count := range counts {
		if first {
			minID = id
			maxID = id
			minCount = count
			maxCount = count
			first = false
		}
		if id < minID {
			minID=id
			minCount=count
		}
		if id > maxID {
			maxID = id
			maxCount = count
		}
	}
	fmt.Println(minID, minCount)
	fmt.Println(maxID, maxCount)
}
