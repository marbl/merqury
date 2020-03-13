package IO;

import IO.basic.FileReader;
import IO.basic.Wrapper;


public abstract class Rwrapper extends Wrapper{
	public void go(String inFile) {
		startTiming();
		
		FileReader fr = new FileReader(inFile);
		System.err.println("Processing file " + fr.getFileName());
		
		hooker(fr);
		
		fr.closeReader();
		
		printTiming();
	}
	
	public abstract void hooker(FileReader fr);
	
	public abstract void printHelp();

}
