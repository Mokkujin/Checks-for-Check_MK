package main

import (
	"testing"
)

func TestGetCheckStatus(t *testing.T) {
	testcase := []struct {
		ThWarning             int
		ThCritical            int
		HAStatusState         string
		HASessionsCurrent     int
		HASessionsMax         int
		ExpectedStatusResults int
	}{
		{
			ThWarning:             240,
			ThCritical:            280,
			HASessionsMax:         300,
			HASessionsCurrent:     290,
			HAStatusState:         "OPEN",
			ExpectedStatusResults: 2,
		},
		{
			ThWarning:             120,
			ThCritical:            140,
			HASessionsMax:         200,
			HASessionsCurrent:     124,
			HAStatusState:         "OPEN",
			ExpectedStatusResults: 1,
		},
		{
			ThWarning:             120,
			ThCritical:            140,
			HASessionsMax:         200,
			HASessionsCurrent:     110,
			HAStatusState:         "OPEN",
			ExpectedStatusResults: 0,
		},
		{
			ThWarning:             120,
			ThCritical:            140,
			HASessionsMax:         200,
			HASessionsCurrent:     110,
			HAStatusState:         "CLOSED",
			ExpectedStatusResults: 2,
		},
	}
	for _, tc := range testcase {
		result := GetCheckStatus(tc.ThWarning, tc.ThCritical, tc.HASessionsMax, tc.HASessionsCurrent, tc.HAStatusState)
		if result != tc.ExpectedStatusResults {
			t.Fail()
		}
	}
}
