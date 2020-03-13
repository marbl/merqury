package IO.basic;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.zip.GZIPInputStream;

public class BufferedFileReader {
	BufferedReader br;
	String path;
	
	public BufferedFileReader(String path) {
		this.path = path;
		init();
	}
	
	private void init() {
		try {
			if (path.equals("-")) {
				br = new BufferedReader(new InputStreamReader (System.in));
			} else if (path.endsWith(".gz")) {
				br = new BufferedReader(new InputStreamReader(new GZIPInputStream(new FileInputStream(path))));
			} else {
				br = new BufferedReader(new InputStreamReader(new FileInputStream(path)));
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
		str = new StringBuffer();
		try {
			str.append(br.readLine());
		} catch (Exception e) {
			e.printStackTrace();
		}
		return str.toString();
	}
	
	public boolean hasMoreLines() {
		try {
			if (br.ready())	return true;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return false;
	}
	
	public void closeReader() {
		try {
			br.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	/***
	 * Seek forward for n lines
	 * @param offset
	 * @throws IOException 
	 */
	public String seekForward(int offset, int n) throws IOException {
		String line = "";
		try {
			
			br.mark(offset + 2);
			for (int i = 0; i < n; i++) {
				String nextLine = br.readLine();
				if (nextLine == null) {
					System.err.println("Reached end of reference.");
					break;
				}
				line = line + nextLine.trim();
			}
			br.reset();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return line;
	}
	
	/***
	 * Reset the buffered reader, and read from the beginning
	 */
	public void reset() {
		try {
			br.close();
			init();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	
}
