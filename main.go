package main

import "fmt"

func main() {
	fmt.Println("Hello, Pre-Commit Blog!")
	result := Add(5, 3)
	fmt.Printf("5 + 3 = %d\n", result)
}

// Add iki sayıyı toplar
func Add(a, b int) int {
	return a + b
}

// Multiply iki sayıyı çarpar
func Multiply(a, b int) int {
	return a * b
}
