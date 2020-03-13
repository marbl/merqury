package genome;

import java.util.HashMap;

public class Chromosome implements Comparable<Chromosome> {

	private String chr;
	private int chrIntVal;
	
	private static int maxChromIntVal = 25;
	private static HashMap<Integer, String> chromIntStringValMap = new HashMap<Integer, String>();
	private static HashMap<String, Integer> chromStringIntValMap = new HashMap<String, Integer>();
	
	@Override
	public int compareTo(Chromosome chrToComp) {
		if (this.getChromIntVal() < chrToComp.getChromIntVal()) {
			return -1;
		} else {
			return 1;
		}
	}
	
	private int getChromIntVal() {
		return chrIntVal;
	}

	public Chromosome(String chr) {
		this.chr = chr;
		chrIntVal = getChromIntVal(chr);
	}

	private static void initChromMaps() {
		for (int i = 1; i < 23; i++) {
			chromIntStringValMap.put(i, "chr" + i);
			chromStringIntValMap.put("chr" + i, i);
		}
		chromIntStringValMap.put(23, "chrX");
		chromIntStringValMap.put(24, "chrY");
		chromIntStringValMap.put(25, "chrM");
		chromStringIntValMap.put("chrX", 23);
		chromStringIntValMap.put("chrY", 24);
		chromStringIntValMap.put("chrM", 25);
	}
	
	/***
	 * Returns the chromosome in a integer format.
	 * Mapping X, Y, and M to 23, 24, and 25, respectively.
	 * @param chrom a String representation like "chrN"
	 * @return 1~25
	 */
	public static int getChromIntVal(String chrom) {
		if (chromIntStringValMap.size() == 0) {
			initChromMaps();
		}
		
		//chrom = chrom.toLowerCase();
		if (!chrom.contains("chr") && chrom.length() < 3) {
			chrom = "chr" + chrom;
		}
		
		if (chromStringIntValMap.containsKey(chrom)) {
			return chromStringIntValMap.get(chrom);
		} else {
			maxChromIntVal++;
			chromIntStringValMap.put(maxChromIntVal, chrom);
			chromStringIntValMap.put(chrom, maxChromIntVal);
			return  maxChromIntVal;
		}
	}
	
	public String getChromStringVal() {
		return chr;
	}
	
	public static String getChromStringVal(int intVal) {
		return chromIntStringValMap.get(intVal);
	}
	
}
