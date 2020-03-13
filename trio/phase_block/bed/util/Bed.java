/**
 * 
 */
package bed.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.PriorityQueue;

import IO.basic.FileReader;
import genome.Chromosome;
import genome.ChromosomeComparator;
import genome.util.Util;


/**
 * @author Arang Rhie
 *
 */
public class Bed {
	
	public static final int CHROM = 0;
	public static final int START = 1;
	public static final int END = 2;
	public static final int NOTE = 3;
	public static final int MQ = 4;
	public static final int STRAND = 5;
	
	public static final short REGION_START = 0;
	public static final short REGION_END = 1;
	
	private boolean isSorted = false;
	private ArrayList<String> chrStrArray = new ArrayList<String>();
	private PriorityQueue<Chromosome> chrList = new PriorityQueue<Chromosome>(1, new ChromosomeComparator());
	private HashMap<String, ArrayList<Integer>> starts = new HashMap<String, ArrayList<Integer>>();
	private HashMap<String, ArrayList<Integer>> ends = new HashMap<String, ArrayList<Integer>>();
	private HashMap<String, ArrayList<String>> notes = new HashMap<String, ArrayList<String>>();
	private HashMap<String, ArrayList<Integer>> notes2 = new HashMap<String, ArrayList<Integer>>();
	
	public Bed() {
		isSorted = false;
		chrStrArray = new ArrayList<String>();
		chrList = new PriorityQueue<Chromosome>(1, new ChromosomeComparator());
		starts = new HashMap<String, ArrayList<Integer>>();
		ends = new HashMap<String, ArrayList<Integer>>();
		notes = new HashMap<String, ArrayList<String>>();
		notes2 = new HashMap<String, ArrayList<Integer>>();
	}
	
	public Bed(FileReader fr) {
		parseBed(fr);
	}
	
	/***
	 * Is the given position in the specified region?
	 * @param chr
	 * @param pos assuming 1-based
	 * @return TRUE or FALSE
	 * Make sure the given bed file is not self-overlapping for the start sites
	 */
	public boolean isInRegion(String chr, int pos) {
		int closestStart = getClosestStart(chr, pos);
		if (closestStart < 0)	return false;
		if (pos < getEndFromStart(chr, closestStart)) {
			return true;
		}
		return false;
	}
	
	public boolean hasRegion(String contig, int start, int end) {
		System.err.println("[DEBUG] :: " + contig + " " + start + " " + end);
		int closestStart = Util.getRegionStartContainingPos(starts.get(contig), start);
		int closestStartIdx = starts.get(contig).indexOf(closestStart);
		if (closestStart < 0)	return false;
		int closestEnd = ends.get(contig).get(closestStartIdx);
		
		System.err.println("[DEBIG] :: closestStartIdx = " + closestStartIdx + " " +
				contig + " " + closestStart + " " + closestEnd);
		if (start <= closestEnd && closestStart <= end) {
			return true;
		}
		
		if (starts.get(contig).size() > closestStartIdx + 1) {
			closestStart = starts.get(contig).get(closestStartIdx + 1);
			closestEnd = ends.get(contig).get(closestStartIdx + 1);
			System.err.println("[DEBIG] :: closestStartIdx+1 = " + (closestStartIdx+1) + " " +
					contig + " " + closestStart + " " + closestEnd);
			if (start <= closestEnd && closestStart <= end) {
				return true;
			}
		}
		
		
		return false;
	}
	
	/***
	 * Get the closest start position in the Bed regions to the given pos
	 * @param chr
	 * @param pos assuming 1-based
	 * @return closest start position from the given region or -1 if the smallest start is greater than given pos.
	 */
	public int getClosestStart(String chr, int pos) {
		return Util.getRegionStartContainingPos(starts.get(chr), pos - 1);
	}
	
	/***
	 * Parse bed formatted file.
	 * Line starting with \'#\' are ignored.
	 * start: 0-based.
	 * end: exclusive.
	 * start 0 end 100 => spanning from 0 - 99.
	 * @param fr
	 */
	public void parseBed(FileReader fr) {
		String line;
		String[] tokens;
		while (fr.hasMoreLines()) {
			line = fr.readLine();
			if (line.startsWith("#"))	continue;
			tokens = line.split("\t");
			if (tokens.length < 3)	continue;
			if (!chrStrArray.contains(tokens[CHROM])) {
				chrStrArray.add(tokens[CHROM]);
				chrList.add(new Chromosome(tokens[CHROM]));
			}
			if (tokens.length > NOTE) {
				StringBuffer note = new StringBuffer(tokens[NOTE]);
				if (NOTE + 1 <= tokens.length) {
					for (int i = NOTE + 1; i < tokens.length; i++) {
						note.append("\t" + tokens[i]);
					}
				}
				addRegion(tokens[CHROM], tokens[START], tokens[END], note.toString());	
			} else {
				addRegion(tokens[CHROM], tokens[START], tokens[END], "");
			}
		}
		sortChrList();
		//System.out.println("[DEBUG] :: chrList.size() = " + chrList.size());
		//System.out.println("[DEBUG] :: ParseBed : numChrList = " + chrList.size());
	}
	
	public void sort() {
		if (!isSorted) {
			sortStartEnds();
			isSorted = true;
		}
	}
	
	private void sortStartEnds() {
		ArrayList<Integer> sortedStarts = new ArrayList<Integer>();
		ArrayList<Integer> sortedEnds = new ArrayList<Integer>();
		ArrayList<String> sortedNotes = new ArrayList<String>();
		for (String chr : chrStrArray) {
			ArrayList<Integer> startRegion = starts.get(chr);
			ArrayList<Integer> endRegion = ends.get(chr);
			ArrayList<String> noteRegion = notes.get(chr);
			Integer[] startRegionArr = new Integer[0];
			startRegionArr = startRegion.toArray(startRegionArr);
			Arrays.sort(startRegionArr);
			sortedStarts = new ArrayList<Integer>();
			sortedEnds = new ArrayList<Integer>();
			sortedNotes = new ArrayList<String>();
			for (int i = 0; i < startRegionArr.length; i++) {
				//System.out.println("[DEBUG] :: " + chr + " startRegionArr[i]=" + startRegionArr[i]);
				sortedStarts.add(startRegionArr[i]);
				int indexOfSortedVal = startRegion.indexOf(startRegionArr[i]);
				sortedEnds.add(endRegion.get(indexOfSortedVal));
				sortedNotes.add(noteRegion.get(indexOfSortedVal));
				endRegion.remove(indexOfSortedVal);
				noteRegion.remove(indexOfSortedVal);
				startRegion.remove(indexOfSortedVal);
			}
			starts.put(chr, sortedStarts);
			ends.put(chr, sortedEnds);
			notes.put(chr, sortedNotes);
		}
	}

	/***
	 * Add regoin to starts and ends map.
	 * @param chr
	 * @param start
	 * @param end
	 */
	public void addRegion(String chr, String start, String end) {
		isSorted = false;
		if (start.contains(",")) {
			start = start.replace(",", "");
		}
		if (end.contains(",")) {
			end = end.replace(",", "");
		}
		if (starts.containsKey(chr)) {
			ArrayList<Integer> startRegion = starts.get(chr);
			startRegion.add(Integer.parseInt(start));
			ArrayList<Integer> endRegion = ends.get(chr);
			endRegion.add(Integer.parseInt(end));
		} else {
			ArrayList<Integer> startRegion = new ArrayList<Integer>();
			startRegion.add(Integer.parseInt(start));
			starts.put(chr, startRegion);
			ArrayList<Integer> endRegion = new ArrayList<Integer>();
			endRegion.add(Integer.parseInt(end));
			ends.put(chr, endRegion);
		}
	}
	
	public void addRegion(String chr, String start, String end, String note) {
		addRegion(chr, start, end);
		if (notes.containsKey(chr)) {
			notes.get(chr).add(note);
		} else {
			ArrayList<String> noteRegion = new ArrayList<String>();
			noteRegion.add(note);
			notes.put(chr, noteRegion);
		}
	}
	
	/**
	 *  Add regions to starts and ends while merging overlaps. notes will be the number of regions merged.
	 * @param chr
	 * @param start
	 * @param end
	 */
	public void addMergeRegion(String chr, String start, String end) {
		isSorted = false;
		if (start.contains(",")) {
			start = start.replace(",", "");
		}
		if (end.contains(",")) {
			end = end.replace(",", "");
		}

		int s = Integer.parseInt(start);
		int e = Integer.parseInt(end);
		int len = (e - s);
		int numMerged = 1;
		if (chrStrArray.contains(chr)) {
			
			ArrayList<Integer> startRegion = starts.get(chr);
			ArrayList<Integer> endRegion = ends.get(chr);
			ArrayList<String> noteRegion = notes.get(chr);
			ArrayList<Integer> note2Region = notes2.get(chr);


			int smallerStartIdx = Util.getRegionStartIdxContainingPos(startRegion, s);
			
			if (smallerStartIdx == -1 && e <= startRegion.get(0)
			 || smallerStartIdx > -1 && smallerStartIdx + 1 < endRegion.size() 
			 	&& s >= endRegion.get(smallerStartIdx) && e <= startRegion.get(smallerStartIdx + 1)
			 || smallerStartIdx + 1 == startRegion.size() && s >= endRegion.get(smallerStartIdx)) {
				//       |---|
				// |---|
				//  or
				// |---|       |---|
				//       |---|
				//  or
				// |---|
				//       |---|
				startRegion.add(smallerStartIdx + 1, s);
				endRegion.add(smallerStartIdx + 1, e);
				noteRegion.add(smallerStartIdx + 1, "1");
				note2Region.add(smallerStartIdx + 1, len);
			} else if (smallerStartIdx + 1 < endRegion.size()) {
				//System.out.println(smallerStartIdx + " " + endRegion.get(smallerStartIdx) + " " + s + " " + startRegion.get(smallerStartIdx + 1));
				if (e > startRegion.get(smallerStartIdx + 1)) {
					// ----|      |----
					//         |-----|
					// or
					// ----|  |----
					//   |-------|
					if (smallerStartIdx == -1 || s > endRegion.get(smallerStartIdx)) {
						// No overlap wi smallerStartIdx
						// ----|      |----
						//         |-----|
						startRegion.add(smallerStartIdx + 1, s);
						endRegion.add(smallerStartIdx + 1, Math.max(e, endRegion.get(smallerStartIdx + 1)));
						noteRegion.add(smallerStartIdx + 1, numMerged + "");
						note2Region.add(smallerStartIdx + 1, len);
						smallerStartIdx++;
					} else {
						// Overlap wi smallerStartIdx
						// ----|  |----
						//   |-------|
						startRegion.set(smallerStartIdx, Math.min(startRegion.get(smallerStartIdx), s));
						endRegion.set(smallerStartIdx, Math.max(e, endRegion.get(smallerStartIdx + 1)));
						numMerged += Integer.parseInt(noteRegion.get(smallerStartIdx));
						noteRegion.set(smallerStartIdx, numMerged + "");
						len += note2Region.get(smallerStartIdx);
						note2Region.set(smallerStartIdx, len);
					}
					while (smallerStartIdx + 1 < endRegion.size() && e > startRegion.get(smallerStartIdx + 1)) {
						// --| |---|     or  --| |---|   : starts, ends
						// ------|           ----------| : s, e
						startRegion.remove(smallerStartIdx + 1);
						endRegion.set(smallerStartIdx, Math.max(e, endRegion.get(smallerStartIdx + 1)));
						endRegion.remove(smallerStartIdx + 1);
						numMerged += Integer.parseInt(noteRegion.get(smallerStartIdx + 1));
						noteRegion.remove(smallerStartIdx + 1); 
						noteRegion.set(smallerStartIdx, numMerged + "");
						len += note2Region.get(smallerStartIdx + 1);
						note2Region.remove(smallerStartIdx + 1); 
						note2Region.set(smallerStartIdx, len);
					}
				} else if (smallerStartIdx > -1) {
					// |----|    |---   or   |------|  |---
					//    |----|               |--|
					endRegion.set(smallerStartIdx, Math.max(e, endRegion.get(smallerStartIdx)));
					numMerged += Integer.parseInt(noteRegion.get(smallerStartIdx));
					noteRegion.set(smallerStartIdx, numMerged + "" );
					len += note2Region.get(smallerStartIdx);
					note2Region.set(smallerStartIdx, len);
				}
			} else if (smallerStartIdx + 1 == endRegion.size()){
				endRegion.set(smallerStartIdx, Math.max(e, endRegion.get(smallerStartIdx)));
				numMerged += Integer.parseInt(noteRegion.get(smallerStartIdx));
				noteRegion.set(smallerStartIdx, numMerged + "" );
				len += note2Region.get(smallerStartIdx);
				note2Region.set(smallerStartIdx, len);
			} else {
				System.out.println("[DEBUG] :: ?? " + s + " " + e);
			}
			
//			System.out.println("[DEBUG] :: " + s + " " + e + "  " + smallerStartIdx + " " + startRegion.size() + " " + endRegion.size() + " " + numMerged);
//			for (int i = 0; i < startRegion.size(); i++) {
//				System.out.print("\t" + startRegion.get(i) + "-" + endRegion.get(i) + "(" + noteRegion.get(i) + ")");
//			}
//			System.out.println();
		} else {
			chrStrArray.add(chr);
			ArrayList<Integer> startRegion = new ArrayList<Integer>();
			startRegion.add(Integer.parseInt(start));
			starts.put(chr, startRegion);
			ArrayList<Integer> endRegion = new ArrayList<Integer>();
			endRegion.add(Integer.parseInt(end));
			ends.put(chr, endRegion);
			ArrayList<String> noteRegion = new ArrayList<String>();
			noteRegion.add("1");
			notes.put(chr, noteRegion);
			ArrayList<Integer> note2Region = new ArrayList<Integer>();
			note2Region.add(len);
			notes2.put(chr, note2Region);
			//System.out.println("[DEBUG] :: " + start + " " + end + "  init " + startRegion.size() + " " + endRegion.size());
		}
	}
	
	/***
	 * Get number of regions contained in specified chr.
	 * @param chr
	 * @return
	 */
	public int getNumRegions(String chr) {
		return starts.get(chr).size();
	}
	
	public ArrayList<Integer> getStarts(String chr) {
		return starts.get(chr);
	}
	
	public ArrayList<Integer> getEnds(String chr) {
		return ends.get(chr);
	}
	
	public ArrayList<String> getNotes(String chr) {
		return notes.get(chr);
	}
	
	/***
	 * 
	 * @param chr
	 * @param index
	 * @return region[REGION_START, REGION_END]
	 */
	public long[] getRegion(String chr, int index) {
		long[] region = new long[2];
		region[REGION_START] = starts.get(chr).get(index);
		region[REGION_END] = ends.get(chr).get(index);
		return region;
	}
	
	public String getNote(String chr, int index) {
		return notes.get(chr).get(index);
	}
	
	/***
	 * 
	 * @param chr
	 * @param index
	 * @return Start of the index's region in chr
	 */
	public Integer getStartFromIdx(String chr, int index) {
		return starts.get(chr).get(index);
	}
	
	/***
	 * 
	 * @param chr
	 * @param index
	 * @return End of the index's region in chr
	 */
	public Integer getEndFromIdx(String chr, int index) {
		return ends.get(chr).get(index);
	}
	
	/***
	 * Get the end position of the region with a specific start positions
	 * @param chr
	 * @param start assuming the bed file has unique start positions
	 * @return end value from the matching given start position
	 */
	public Integer getEndFromStart(String chr, int start) {
		return ends.get(chr).get(starts.get(chr).indexOf(start));
	}

	
	public static String getNotes(String[] bedLine) {
		StringBuffer notes = new StringBuffer();
		if (bedLine.length > NOTE) {
			notes.append(bedLine[NOTE]);
			if (bedLine.length > NOTE + 1) {
				for (int i = NOTE + 1; i < bedLine.length; i++) {
					notes.append("\t" + bedLine[i]);
				}
			}
		}
		return notes.toString();
	}
	
	public static int getChromIntVal(String[] bedLine) {
		return Chromosome.getChromIntVal(bedLine[CHROM]);
	}
	
	public static int getStart(String[] bedLine) {
		return Integer.parseInt(bedLine[START]);
	}
	
	public static int getEnd(String[] bedLine) {
		return Integer.parseInt(bedLine[END]);
	}

	/**
	 * @return
	 */
	public int getChromosomes() {
		return chrStrArray.size();
	}
	
	
	private void sortChrList() {
		Chromosome[] chrArray = null;
		chrArray = new Chromosome[0];
		System.err.println("[DEBUG] :: chrList.size() = " + chrList.size());
		chrArray = chrList.toArray(chrArray);
		Arrays.sort(chrArray);
		System.err.println("[DEBUG] :: chrArray.length = " + chrArray.length);
		chrList.clear();
		chrStrArray.clear();
		for (int i = 0; i < chrArray.length; i++) {
			chrList.add(chrArray[i]);
			chrStrArray.add(chrArray[i].getChromStringVal());
		}
	}
	
	public String getChr(int index) {
		return chrStrArray.get(index);
	}
	
	public Chromosome getChromosome(int index) {
		Chromosome[] chrArray = new Chromosome[0];
		return chrList.toArray(chrArray)[index];
	}
	
	public PriorityQueue<Chromosome> getChrList() {
		return chrList;
	}
	
	public ArrayList<String> getChrStringList() {
		if (chrStrArray.size() != chrList.size()) {
			PriorityQueue<Chromosome> newChrList = new PriorityQueue<Chromosome>(); 
			while (!chrList.isEmpty()) {
				Chromosome chrom = chrList.remove();
				newChrList.add(chrom);
				chrStrArray.add(chrom.getChromStringVal());
			}
			chrList = newChrList;
		}
		return chrStrArray;
	}
	
	public boolean hasChromosome(String chr) {
		return chrList.contains(chr);
	}

	public void sortChr() {
		Collections.sort(chrStrArray);
	}

	public ArrayList<Integer> getNotes2(String chr) {
		return notes2.get(chr);
	}

	public int getBasesInRegion(String contig, int start, int end) {
		int bases = 0;
		for (int pos = start + 1; pos <= end; pos++) {
			if (isInRegion(contig, pos)) {
				bases++;
			}
		}
		
		int closestStart = Util.getRegionStartContainingPos(starts.get(contig), start);
		int closestEnd;
		if (closestStart > 0) {
			closestEnd = ends.get(contig).get(starts.get(contig).indexOf(closestStart));
			if (start < closestEnd) {
				bases += (start - closestStart);
			}
		}
		
		closestStart = Util.getRegionStartContainingPos(starts.get(contig), end);
		if (closestStart > 0) {
			closestEnd = ends.get(contig).get(starts.get(contig).indexOf(closestStart));
			if (end < closestEnd) {
				bases += (closestEnd - end);
			}
		}
		return bases;
	}
	
	/***
	 * Get the specificed idx line of chr
	 * @param chr
	 * @param idx
	 * @return
	 */
	public String getLine(String chr, int idx) {
		String line = "";
		if (chrStrArray.contains(chr)) {
			line = chr + "\t" + starts.get(chr).get(idx) + "\t" + ends.get(chr).get(idx) + "\t" + notes.get(chr).get(idx);
		} else {
			System.err.println("No chromosome (contig) named " + chr + " exists. exiting.");
			System.exit(-1);
		}
		return line;
	}

}
