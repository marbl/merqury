package bed.util;

import java.util.ArrayList;
import java.util.HashMap;

import genome.util.Util;

public class Region {
	private int start = -1;
	private int end = -1;
	private String notes = "";
	private boolean strand = true; // TRUE = +, FALSE = -
	
	public Region(int start, int end, String notes) {
		this.start = start;
		this.end = end;
		this.notes = notes;
	}
	
	public Region(int start, int end, boolean strand) {
		this.start = start;
		this.end = end;
		this.strand = strand;
	}
	
	public Region(String chr, int start, int end) {
		this.start = start;
		this.end = end;
	}
	
	public boolean isInRegion(int pos) {
		if (start < pos && pos <= end) {
			return true;
		}
		return false;
	}
	
	public boolean getStrand() {
		return strand;
	}
	
	public String getName() {
		return this.notes;
	}
	
	public int getStart() {
		return this.start;
	}
	
	public int getEnd() {
		return this.end;
	}
	
	public static boolean isInRegion(int pos, ArrayList<Integer> startList, HashMap<Integer, Integer> startToEnd) {
		int closestStart = Util.getRegionStartContainingPos(startList, pos);
		if (closestStart < 0)	return false;
		if (pos <= startToEnd.get(closestStart)) {
			return true;
		} else {
			return false;
		}
	}
}
