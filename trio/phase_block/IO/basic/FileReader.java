package IO.basic;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.Scanner;
import java.util.zip.GZIPInputStream;

/**
 * Reads specified file
 * @author Arang
 *
 */
public class FileReader {

	Scanner br;
	//BufferedReader br;
	String path;
	
	/***
	 * Reads specified file.
	 * File path directory can be written with "/" or "\\". 
	 * @param path
	 */
	public FileReader(String path) {
		this.path = path;
		init();
	}
	
	private void init() {
		try {
			if (path.equals("-")) {
				br = new Scanner(System.in);
			} else if (path.endsWith(".gz")) {
				br = new Scanner(new BufferedReader(new InputStreamReader(new GZIPInputStream(new FileInputStream(path)))));
			} else {
				br = new Scanner(new File(path));
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	/***
	 * The full path of this FileReader file pointer.
	 * @return The given path including directory, file name
	 */
	public String getFullPath() {
		return path;
	}
	
	public String getDirectory() {
		return IOUtil.retrieveDirectory(path);
	}
	
	public String getFileName() {
		return IOUtil.retrieveFileName(path);
	}
	
	StringBuffer str = new StringBuffer("");
	
	/***
	 * Reads file specified with FileReader object.
	 * @return the line cascaded from the last line,
	 * or null if the line has reached to end of the file.
	 * 
	 */
	public String readLine(){
		return br.nextLine();
	}
	
	public String getLastLine() {
		return str.toString();
	}

	public boolean hasMoreLines() {
		if (br.hasNextLine())	return true;
		return false;
	}
	
	public void closeReader() {
		br.close();
	}
	
	/***
	 * Reset the buffered reader, and read from the beginning
	 */
	public void reset() {
		br.close();
		init();
	}
	
}
