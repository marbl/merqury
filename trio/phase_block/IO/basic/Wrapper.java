package IO.basic;

import java.text.MessageFormat;

public abstract class Wrapper {
	
	long startTime = 0;
	
	protected void startTiming() {
		startTime = System.currentTimeMillis();
	}
	
	protected void printTiming() {
		long runningTime = (System.currentTimeMillis() - startTime) / 1000;
		long m = (runningTime/60);
		long h = m/60;
		m -= h*60;
		long sec = runningTime%60;
		
		System.err.println(MessageFormat.format("Running time : {0} h {1} m {2} sec", h, m, sec));
		System.err.println();
	}

	public abstract void printHelp();
}
