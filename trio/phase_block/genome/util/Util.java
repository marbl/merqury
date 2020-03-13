package genome.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.Vector;

import IO.basic.FileReader;

public class Util {
	
	public static Integer[] initArr(int size) {
		Integer[] arr = new Integer[size];
		for (int i = 0; i < size; i++) {
			arr[i] = 0;
		}
		return arr;
	}

	/***
	 * Get the closest, smaller START position of a startList containing pos
	 * @param startList
	 * @param pos
	 * @return -1 if pos is smaller than the smallest START
	 * 
	 * *When the startList is 0-based, the pos must be also 0-based.
	 */
	public static int getRegionStartContainingPos(ArrayList<Integer> startList, int pos) {
		int posInStartIdx = Collections.binarySearch(startList, pos);
		// posInStartIdx will be the closest index of start position that is equals or smaller than the given pos
		if (posInStartIdx < 0) {
			posInStartIdx *= -1;
			posInStartIdx -= 2;
		}
		// all STARTs are smaller than pos
		if (posInStartIdx < 0 || posInStartIdx == startList.size()) {
			return -1;
		}
		return startList.get(posInStartIdx);
	}
	
	/***
	 * Get the closest, smaller START position of startList containing pos
	 * @param startList
	 * @param pos
	 * @return -1 if pos is smaller than the smallest START
	 */
	public static int getRegionStartIdxContainingPos(ArrayList<Integer> startList, int pos) {
		int posInStartIdx = Collections.binarySearch(startList, pos);
		// posInStartIdx will be the closest, min SNP equals or smaller than the pos
		if (posInStartIdx < 0) {
			posInStartIdx *= -1;
			posInStartIdx -= 2;
		}
		// all STARTs are smaller than pos
		if (posInStartIdx < 0 || posInStartIdx == startList.size()) {
			return -1;
		}
		return posInStartIdx;
	}
	
	
	public static int getRegionEndIdxContainingPos(ArrayList<Integer> endList, int pos) {
		int posInEndIdx = Collections.binarySearch(endList, pos);
		// posInEndIdx will be the closest, equals to or larger than the pos
		if (posInEndIdx < 0) {
			posInEndIdx += 1;
			posInEndIdx *= -1;
		}
		
		// all ENDs are smaller than pos
		if (posInEndIdx == endList.size()) {
			return -1;
		}
		
		if (pos > endList.get(posInEndIdx)) {
			return -1;
		}
		
		return posInEndIdx;
	}
	
	/***
	 * 
	 * @param sortedContigLenArr	ArrayList of contig length. Use Collection.sort(sortedContigLenArr) before running this method
	 * @param contigLenSum	Total len sum of all contigs
	 * @return
	 */
	public static double getN50(ArrayList<Double> sortedContigLenArr, double contigLenSum) {
		double n50comp = contigLenSum / 2;
		double n50 = 0;
		double lenSum = 0;
		//System.out.println("Longest block (contig) size:\t" + Format.numbersToDecimal(sortedContigLenArr.get(sortedContigLenArr.size() - 1)));
		for (int i = sortedContigLenArr.size() - 1; i >= 0; i--) {
			lenSum += sortedContigLenArr.get(i);
			if (lenSum > n50comp) {
				n50 = sortedContigLenArr.get(i);
				System.out.println("L50: " + (sortedContigLenArr.size()  - i));
				break;
			}
		}
		return n50;
	}
	
	
	/***
	 * Returns the chromosome in a integer format.
	 * Mapping X, Y, and M to 23, 24, and 25, respectively.
	 * @param chrom a String representation like "chrN"
	 * @return 1~25
	 */
	public static int getChromIntVal(String chrom) {
		chrom = chrom.replace("chr", "");
		int chr = 0; 
		if (chrom.equals("X")) {
			chrom = "23";	// X
		} else if (chrom.equals("Y")) {
			chrom = "24";	// Y
		} else if (chrom.equals("M")) {
			chrom = "25";	// Mitocondria
		}
		chr = (byte) Integer.parseInt(chrom);
		return chr;
	}
	
	public static String getChromStringVal(int chr) {
		switch(chr) {
		case 23: return "chrX";
		case 24: return "chrY";
		case 25: return "chrM";
		}
		return "chr" + String.valueOf(chr);
	}
	
	/***
	 * Returns the chromosome in a String format.
	 * Mapping back 23, 24, 25 to X, Y, and M.
	 * @param chr
	 * @return 1~22, X, Y, and M. M stands for Mitochondria.
	 */
	public static String getHumanChromosome(byte chr) {
		switch(chr) {
		case 23: return "X";
		case 24: return "Y";
		case 25: return "M";
		}
		return String.valueOf(chr);
	}
	
	public static boolean isAutosome(String chr) {
		if (chr.endsWith("X") || chr.endsWith("Y") || chr.endsWith("M")) {
			return false;
		}
		return true;
	}
	
	public static boolean isChrX(String chr) {
		if (chr.endsWith("X"))	return true;
		return false;
	}

	public static int toInt(byte b) {
		return (int) b >= 0 ? b : (int)b + (int) Math.pow(2, 8);
	}
	
	/***
	 * Parse a 4-byte long int primitive to an unsigned intended
	 * byte array of length 4.
	 * @param intNum 4-byte long int
	 * @return byte[4]
	 */
	public static byte[] to4Bytes(int intNum) {
		byte[] keys = new byte[4];
		int k0 = intNum/(int)Math.pow(2, 24);
		keys[0] = (byte) k0;
		intNum -= k0*(int)Math.pow(2, 24);
		int k1 = intNum/(int)Math.pow(2, 16);
		keys[1] = (byte) k1;
		intNum -= k1*(int)Math.pow(2, 16);
		int k2 = intNum/(int)Math.pow(2, 8);
		keys[2] = (byte) k2;
		intNum -= k2*(int)Math.pow(2, 8);
		keys[3] = (byte) intNum;
		return keys;
	}
	
	/***
	 * Parse a 4-byte long int primitive to an unsigned intended
	 * byte array of length 4.
	 * @param intNum 4-byte long int
	 * @return byte[4]
	 */
	public static byte[] to2Bytes(int intNum) {
		byte[] keys = new byte[2];
		int k2 = intNum/(int)Math.pow(2, 8);
		keys[0] = (byte) k2;
		intNum -= k2*(int)Math.pow(2, 8);
		keys[1] = (byte) intNum;
		return keys;
	}
	
	/***
	 * Parse back from a byte array to a 4-byte long integer number.
	 * @param bytes	bytes to parse, length of 4.
	 * @return 32-bit long, signed integer number.
	 */
	public static int to4Int(byte[] bytes) {
		int intVal = 0;
		int hat2of8 = (int) Math.pow(2, 8);
		int key0 = (int) bytes[0] >= 0 ? bytes[0] : (int)bytes[0] + hat2of8;
		int key1 = (int) bytes[1] >= 0 ? bytes[1] : (int)bytes[1] + hat2of8;
		int key2 = (int) bytes[2] >= 0 ? bytes[2] : (int)bytes[2] + hat2of8;
		int key3 = (int) bytes[3] >= 0 ? bytes[3] : (int)bytes[3] + hat2of8;
		intVal = (key0 << 24) + (key1 << 16) + (key2 << 8) + key3;
		return intVal;
	}
	
	public static int to4Int(byte byte1, byte byte2, byte byte3, byte byte4) {
		byte[] bytes = new byte[4];
		bytes[0] = byte1;
		bytes[1] = byte2;
		bytes[2] = byte3;
		bytes[3] = byte4;
		return to4Int(bytes);
	}
	
	/***
	 * Parse back from a byte array to a 2-byte long integer number.
	 * @param bytes	bytes to parse, length of 2.
	 * @return 32-bit long, signed integer number.
	 */
	public static int to2Int(byte[] bytes) {
		int intVal = 0;
		int hat2of8 = (int) Math.pow(2, 8);
		int key0 = (int) bytes[0] >= 0 ? bytes[0] : (int)bytes[0] + hat2of8;
		int key1 = (int) bytes[1] >= 0 ? bytes[1] : (int)bytes[1] + hat2of8;
		intVal = (key0 << 8) + key1;
		return intVal;
	}
	
	public static int to2Int(byte byte1, byte byte2) {
		byte[] bytes = new byte[2];
		bytes[0] = byte1;
		bytes[1] = byte2;
		return to2Int(bytes);
	}
	
	public static ArrayList<FileReader> sortFilesInChromOrder(ArrayList<FileReader> frs) {
		Vector<String> fileNameVector = new Vector<String>();
		ArrayList<FileReader> sortedList = new ArrayList<FileReader>();
		HashMap<String, Integer> fileNameIdxMap = new HashMap<String, Integer>();
		for (int i = 0; i < frs.size(); i++) {
			FileReader fr = frs.get(i);
			fileNameVector.add(fr.getFileName());
			fileNameIdxMap.put(fr.getFileName(), i);
		}
		fileNameVector = sortInChromOrder(fileNameVector);
		for (String fileName : fileNameVector) {
			sortedList.add(frs.get(fileNameIdxMap.get(fileName)));
		}
		return sortedList;
	}
	
	public static Vector<String> sortInChromOrder(Vector<String> inList) {
		Vector<String> outList = new Vector<String>();
		Vector<String> one = new Vector<String>();
		Vector<String> ten = new Vector<String>();
		Vector<String> rest = new Vector<String>();
		String chrX = "";
		String chrY = "";
		String chrM = "";
		for (String value : inList) {
			int chrIdx = value.indexOf("chr");
			if (chrIdx == -1) {
				System.out.println("No \'chr\' found. This file will be added at the end.");
				rest.add(value);
			}
			if (value.charAt(chrIdx + 3) == 'X') {
				chrX = value;
			} else if (value.charAt(chrIdx + 3) == 'Y') {
				chrY = value;
			} else if (value.charAt(chrIdx + 3) == 'M') {
				chrM = value;
			} else if (value.charAt(chrIdx + 4) >= '0' && value.charAt(chrIdx + 4) <= '9') {
				ten.add(value);
			} else {
				one.add(value);
			}
		}
		String[] oneArr = new String[one.size()];
		oneArr = one.toArray(oneArr);
		String[] tenArr = new String[ten.size()];
		tenArr = ten.toArray(tenArr);
		String[] restArr = new String[rest.size()];
		rest.toArray(restArr);
		Arrays.sort(oneArr);
		Arrays.sort(tenArr);
		Arrays.sort(restArr);
		for (String val : oneArr) {
			outList.add(val);
		}
		for (String val : tenArr) {
			outList.add(val);
		}
		if (!chrX.equals("")) {
			outList.add(chrX);
		}
		if (!chrY.equals("")) {
			outList.add(chrY);
		}
		if (!chrM.equals("")) {
			outList.add(chrM);
		}
		for (String val : restArr) {
			outList.add(val);
		}
		return outList;
	}

	
	
}
