import IO.Rwrapper;
import IO.basic.FileMaker;
import IO.basic.FileReader;
import IO.basic.RegExp;
import bed.util.Bed;

public class MerToPhaseBlock extends Rwrapper{

	private static String	outPrefix	= "out";
	private static boolean	noBreak		= true;
	
	/***
	 * Num. of switches allowed to be "Short" switch in a block.
	 * 	1 = 1 switch to the other haplotype with an immediate switch back
	 */
	private static int		shortNum	= 1;
	
	/***
	 * If shortNum > 1, the switches has to be occur in less than this limit.
	 * 	200 = 200 bp. Any short switches occurring <= shortNum times within shortLimit will be included in a block.
	 * 	Switches > shortLimit will become its own block. 
	 */
	private static int		shortLimit	= 200;
	
	public static void main(String[] args) {
		if (args.length == 4) {
			outPrefix	= args[1];
			shortNum	= Integer.parseInt(args[2]);
			shortLimit	= Integer.parseInt(args[3]);
			new MerToPhaseBlock().go(args[0]);
		} else if (args.length == 5) {
			outPrefix	= args[1];
			shortNum	= Integer.parseInt(args[2]);
			shortLimit	= Integer.parseInt(args[3]);
			if (args[4].equals("T") || args[4].equals("no-break")) {
				System.err.println();
				System.err.println("Assuming phased assembly.");
				System.err.println("Gaps will be included for computing phased blocks.");
				System.err.println();
				noBreak = true;
			} else if (args[4].equals("F") || args[4].equals("break")) {
				System.err.println();
				System.err.println("Phased blocks will break at gaps.");
				System.err.println();
				noBreak = false;
			}
			new MerToPhaseBlock().go(args[0]);
		} else {
			new MerToPhaseBlock().printHelp();
		}
	}

	@Override
	public void hooker(FileReader fr) {
		
		FileMaker outSwitch	= new FileMaker(outPrefix + ".switch.bed");
		FileMaker outBlock	= new FileMaker(outPrefix + ".phased_block.bed");
		
		String line;
		String[] tokens;
		
		String scaff	= "";
		double start	= -1;
		double end		= -1;
		String name		= "";
		
		String prevScaff	= "";
		String prevBlock	= "";
		double blockStart	= -1;
		double blockEnd		= -1;
		double shortStart	= -1;
		double shortEnd		= -1;
		
		int numMarkers		= 0;
		int numSwitches		= 0;		// Num. of total switches found in a block
		int numShortSwitches	= 0;	// Num. of temporary short range switches found in a raw
		double distFromSwitch	= -1;	// Distance (bp) from previous switch
		
		boolean isShortSwitch	= true;
		
		String hap1 = "";
		String hap2 = "";
		
		// Get hap1 and hap2
		while (fr.hasMoreLines()) {
			line	= fr.readLine();
			tokens	= line.split(RegExp.TAB);
			name	= tokens[Bed.NOTE];
			if (!name.equals("gap")) {
				if (hap1.equals("")) {
					hap1 = name;
					continue;
				} else {
					if (!hap1.equals(name)) {
						hap2 = name;
						break;
					}
				}
			}
		}
		
		System.err.println("Found " + hap1 + " and " + hap2 + " as haplotypes.");
		fr.reset();
		
		// Mark switches
		while (fr.hasMoreLines()) {
			line	= fr.readLine();
			tokens	= line.split(RegExp.TAB);
			scaff	= tokens[Bed.CHROM];
			start	= Double.parseDouble(tokens[Bed.START]);
			end		= Double.parseDouble(tokens[Bed.END]);
			name	= tokens[Bed.NOTE];
			
			// If noBreak = F (default), gaps will be excluded.
			if (name.equals("gap")) {
				if (noBreak) {
					System.err.println("Ignoring " + line);
					continue;
				}
				
				// extend the block end to the gap boundaries
				blockEnd	= start;
				if (!prevScaff.equals("")) {
					writeBlock(outBlock, prevScaff, blockStart, blockEnd, prevBlock, numSwitches, numMarkers);
				}
				prevScaff 	= scaff;
				blockStart	= end;
				blockEnd	= end;
				prevBlock	= "unknown";
				numMarkers		= 0;
				numSwitches		= 0;
				isShortSwitch	= false;
				continue;
			}
			
			// new scaff: set default to "same"
			if (prevScaff.equals("") || !scaff.equals(prevScaff)) {
				// not the first line, new scaff
				if (!prevScaff.equals("")) {
					// check if we had short switches at the end of a tig.
					// write down previous block
					numMarkers	-= numShortSwitches;	// include the overhead total markers
					writeBlock(outBlock, prevScaff, blockStart, blockEnd, prevBlock, numSwitches, numMarkers);
					if (numShortSwitches > 0) {	// All short switches at the end are considered as long range switches.
						// initialize new block
						blockStart	= shortStart;
						blockEnd	= shortEnd;
						numMarkers	= numShortSwitches;	// numShortSwitches: carry over the overhead; 1: current marker?
						prevBlock = (name.equals(hap1)) ? hap1 : hap2; 
						//outSwitch.writeLine(line + "\tLong\t" + prevBlock);
						writeBlock(outBlock, prevScaff, blockStart, blockEnd, prevBlock, numSwitches, numMarkers);
					}
				}
				
				
				prevBlock		= name;
				numSwitches		= 0;
				numShortSwitches = 0;
				distFromSwitch	= 0;
				numMarkers		= 0;
				blockStart		= start;
				blockEnd		= end;
				if (name.equals(hap1) || name.equals(hap2)) {
					numMarkers++;
				}
				outSwitch.writeLine(line + "\tSame\t" + prevBlock);
				isShortSwitch = false;
			} else {	// same scaff
				numMarkers++;

				// same block?
				// same hap -> hap or non-hap (unknown) -> hap (pat/mat)
				if (prevBlock.equals(name) || prevBlock.equals("unknown")) {
					blockEnd	= end;

					// unknown -> hap (pat/mat)
					if (prevBlock.equals("unknown")) {
						prevBlock	= name;
					}
					
					// switch back
					if (isShortSwitch) {
						numSwitches += numShortSwitches;
						numShortSwitches = 0;
						isShortSwitch = false;
						outSwitch.writeLine(line + "\tSwitchBack\t" + prevBlock);
					} else {
						outSwitch.writeLine(line + "\tSame\t" + prevBlock);
					}
				}
				
				// Switch detected (prevBlock != name)
				else if (!prevBlock.equals(name)) {
					shortEnd		= end;
					numShortSwitches++;
					
					// First switch?
					if (!isShortSwitch) {
						shortStart	= start;
					} else {
						// is the range falling in the defined "Short range"?
						distFromSwitch	=	shortEnd - shortStart;
						// Long range switch
						if (numShortSwitches >= shortNum || distFromSwitch > shortLimit) {
							// write down previous block
							numMarkers	-= (numShortSwitches);	// include the overhead total markers
							writeBlock(outBlock, scaff, blockStart, blockEnd, prevBlock, numSwitches, numMarkers);

							// initialize new Long block
							blockStart	= shortStart;
							blockEnd	= end;
							numMarkers	= numShortSwitches;	// numShortSwitches: carry over the overhead; 1: current marker
							numSwitches	= 0;
							numShortSwitches = 0;
							prevBlock = name;
							isShortSwitch = false;
							outSwitch.writeLine(line + "\tLong\t" + prevBlock);
							continue;
						}
					}
					
					// First and short range switches
					isShortSwitch = true;
					outSwitch.writeLine(line + "\tShort\t" + prevBlock);
				}
			}
			prevScaff = scaff;
		}
		
		// Write down the last block
		writeBlock(outBlock, scaff, blockStart, end, prevBlock, numSwitches, numMarkers);
	}
	
	private void writeBlock(FileMaker fm, String scaff, double start, double end, String name, int numSwitches, int totalMarkers) {
		if (totalMarkers > 1) {
			fm.writeLine(scaff + "\t" + String.format("%.0f", start) + "\t" + String.format("%.0f", end) + "\t" + name + "\t" + String.format("%.3f", ((float) numSwitches/totalMarkers)) + "\t" + numSwitches + "\t" + totalMarkers);
		}
		
	}

	@Override
	public void printHelp() {
		System.err.println("Usage: java -jar bedMerToPhaseBlock.jar <sorted.pos.bed> <out_prefix> <num_switches> <short_limit> [no-break=T]");
		System.err.println("\t<sorted.pos.bed>: Sorted bed file, with the 4th column being the haplotype or gap");
		System.err.println("\t<out_prefix>: Output prefix.");
		System.err.println("\t\t<out_prefix>.phased_block.bed : <scaff> <start> <end> <haplotype> <switch_error> <num. switches> <num. markers>");
		System.err.println("\t\t<out_prefix>.switch.bed : <sorted.pos.bed> with Same/Short/Long and intermediate block state. For debugging.");
		System.err.println("\t\twill be generated.");
		System.err.println("\t<num_switches>: Num. of short switches in a raw allowed within a block.");
		System.err.println("\t\tUsually, this value is set to 1 or 2 to follow the short range switch definition.");
		System.err.println("\t<short_limit>: Maximum allowed distance for short range switches within a block. In bp.");
		System.err.println("\t[no-break]: Don't break at any gap. Gaps will be included in phased_blocks.");
		System.err.println("\t\tDEFAULT=T. Gaps will become part of phased blocks if scaffolds are given.");
		System.err.println("\t\t*Provide \"break\" or \"F\" for getting in-contig phased blocks.");
		System.err.println("Arang Rhie, 2020-02-13. arrhie@gmail.com");
	}

}
