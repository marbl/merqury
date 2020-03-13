package IO.basic;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public class FileMaker {

	private BufferedWriter bw;
	private String dir;
	private String fileName;
	
	/***
	 * Make a file with the directory name and file name
	 * @param directory
	 * @param filename
	 */
	public FileMaker(String directory, String filename){
		try{
			dir = directory;
			fileName = filename;
			File newfile = new File(dir);
			newfile.mkdirs();
			newfile = new File(dir+"/"+fileName);
			if (newfile.exists()) {
				System.err.println("File " + newfile.getName() + " already exists.");
				System.err.println("Do you wish to override? Y,N");
				Character in = (char) System.in.read();
				while (in > 0) {
					in = Character.toLowerCase(in);
					if (in == 'n') {
						System.exit(-9);
					} else if (in == 'y') {
						break;
					} else {
						in = (char) System.in.read();
					}
				}
				
			}
			bw = new BufferedWriter(new FileWriter(newfile));
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	/***
	 * Override a file with the directory name and file name
	 * @param directory
	 * @param filename
	 * @param append If true; append. False; ask to override if the file already exists.
	 */
	public FileMaker(String directory, String filename, boolean append){
		try{
			dir = directory;
			fileName = filename;
			File newfile = new File(dir);
			newfile.mkdirs();
			newfile = new File(dir+"/"+fileName);
			if (!append && newfile.exists()) {
				System.err.println("File " + newfile.getName() + " already exists.");
				System.err.println("Do you wish to override? Y,N");
				Character in = (char) System.in.read();
				while (in > 0) {
					in = Character.toLowerCase(in);
					if (in == 'n') {
						System.exit(-9);
					} else if (in == 'y') {
						break;
					} else {
						in = (char) System.in.read();
					}
				}
				
			}
			bw = new BufferedWriter(new FileWriter(newfile, append));
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	public FileMaker(String filename, boolean append) {
		this(IOUtil.retrieveDirectory(filename), IOUtil.retrieveFileName(filename), append);
	}
	
	public FileMaker(String filename) {
		this(IOUtil.retrieveDirectory(filename), IOUtil.retrieveFileName(filename));
	}
	
	public void setDir(String dir) {
		this.dir = dir;
	}
	
	public String getDir() {
		return dir;
	}
	
	public String getFileName() {
		return fileName;
	}

	/***
	 * Write a line in the FileMaker object
	 * @param text
	 */
	public void writeLine(String text){
		try{
			bw.write(text);
			bw.write("\n");
			bw.flush();
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	public void writeLine(){
		try{
			bw.write("\n");
			bw.flush();
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	public void write(String text){
		try{
			bw.write(text);
			bw.flush();
		}catch(IOException e){
			e.printStackTrace();
		}
	}
	
	public void write(char text) {
		try{
			bw.write(text);
			bw.flush();
		}catch(IOException e){
			e.printStackTrace();
		}
	}
	
	public void closeMaker() {
		try {
			bw.close();
		} catch (Exception e) {
		}
	}
	
	public boolean remove() {
		closeMaker();
		File file = new File(dir+"/"+fileName);
		if (file.exists()) {
			return file.delete();
		} else {
			return false;
		}
	}
}
