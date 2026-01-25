package main

import "testing"

func TestAdd(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"pozitif sayılar", 5, 3, 8},
		{"negatif sayılar", -2, -3, -5},
		{"sıfır ile toplama", 0, 5, 5},
		{"karışık", -5, 10, 5},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Add(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("Add(%d, %d) = %d; beklenen %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

func TestMultiply(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"pozitif sayılar", 5, 3, 15},
		{"negatif ile pozitif", -2, 3, -6},
		{"negatif ile pozitif", -2, -3, -6},
		{"sıfır ile çarpma", 0, 5, 0},
		{"negatif sayılar", -2, -3, 6},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Multiply(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("Multiply(%d, %d) = %d; beklenen %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}
