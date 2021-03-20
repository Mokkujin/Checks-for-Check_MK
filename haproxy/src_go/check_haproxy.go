package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
)

//Config is a struct for json
type Config struct {
	WIUser            string  `json:"WIUser"`
	WIPass            string  `json:"WIPass"`
	HAProxyStatusPage string  `json:"HAProxyStatusPage"`
	MonBackFront      bool    `json:"MonBackFront"`
	HADefMax          int     `json:"HADefMax"`
	MWarnAt           float64 `json:"MWarnAt"`
	MCritAt           float64 `json:"MCritAt"`
}

//LoadConfiguration load config from json file
func LoadConfiguration(file string) (Config, error) {
	var config Config
	configFile, err := os.Open(file)
	defer configFile.Close()
	if err != nil {
		return config, err
	}
	jsonParser := json.NewDecoder(configFile)
	err = jsonParser.Decode(&config)
	return config, err
}

//GetCheckStatus check values and return int for check_mk
func GetCheckStatus(ThWarning int, ThCritical int, HASessionsMax int, HASessionsCurrent int, HAStatusState string) int {
	CheckStatus := 2
	if HAStatusState == "OPEN" || HAStatusState == "UP" {
		if HASessionsCurrent < ThWarning && HASessionsCurrent < ThCritical {
			CheckStatus = 0
		}
		if HASessionsCurrent >= ThWarning {
			CheckStatus = 1
		}
		if HASessionsCurrent >= ThCritical {
			CheckStatus = 2
		}
		if HASessionsMax == 0 || HASessionsCurrent == 0 {
			CheckStatus = 0
		}
	}
	return CheckStatus
}

//main function
func main() {
	config, err := LoadConfiguration("config.json")
	if err != nil {
		fmt.Println("could not load json config")
		os.Exit(3)
	}
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{Transport: tr}
	HARequest, err := http.NewRequest("GET", config.HAProxyStatusPage, nil)
	HARequest.SetBasicAuth(config.WIUser, config.WIPass)
	response, err := client.Do(HARequest)
	if err != nil {
		fmt.Println("error at request please check url to statussite")
		os.Exit(2)
	}
	HAContent, err := ioutil.ReadAll(response.Body)
	if err != nil {
		fmt.Println("error to read request")
		os.Exit(1)
	}
	s := string(HAContent)
	// analyze the output
	for _, line := range strings.Split(strings.TrimSuffix(s, "\n"), "\n") {
		// skip if starts with #
		if strings.HasPrefix(line, "#") {
			continue
		}
		// get informations from line
		hac := strings.Split(line, ",")
		if config.MonBackFront == false {
			if hac[1] == "BACKEND" || hac[1] == "FRONTEND" {
				continue
			}
		}
		// get sessionlimit if not set use default from json
		HASessionsMax, _ := strconv.Atoi(hac[6])
		if HASessionsMax == 0 {
			HASessionsMax = config.HADefMax
		}
		// calculate thresholds
		ThWarning := int(float64(HASessionsMax) * config.MWarnAt)
		ThCritical := int(float64(HASessionsMax) * config.MCritAt)
		// get state
		HaStatusName := hac[0]
		HaStatusElement := hac[1]
		HAStatusState := hac[17]
		HASessionsCurrent, err := strconv.Atoi(hac[4])
		if err != nil {
			fmt.Println("could not get current sessions")
			os.Exit(5)
		}

		ckSt := GetCheckStatus(ThWarning, ThCritical, HASessionsMax, HASessionsCurrent, HAStatusState)

		fmt.Printf("%d haproxy_%s-%s - %s %d/%d Sessions Host is %s"+"\n", ckSt, HaStatusName, HaStatusElement, HaStatusElement, HASessionsCurrent, HASessionsMax, HAStatusState)
	}
}
