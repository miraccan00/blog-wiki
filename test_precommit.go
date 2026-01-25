package main

import "fmt"

// Bu satırın sonunda boşluklar var
func TestFunction() {
	var x = 5 // Formatting hatası - eşittir etrafında boşluk yok
	y := 10   // Formatting hatası

	// Trailing whitespace test
	fmt.Println(x + y) // Formatting hatası - operatör etrafında boşluk yok
}
