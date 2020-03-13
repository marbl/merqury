package IO.basic;

public class Format {
	
	public static String numbersToDecimal(double num) {
		return String.format("%,.0f", num);
	}
	
	public static String numbersToDecimal(int num) {
		return String.format("%,d", num);
	}
}
