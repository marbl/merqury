package IO.basic;

import java.text.SimpleDateFormat;
import java.util.Date;

public class IOUtil {

	public static String retrieveDirectory(String path) {
		String dir = ".";
		if (path.contains("/")) {
			dir = path.substring(0, path.lastIndexOf("/"));
		} else if (path.contains("\\")) {
			dir = path.substring(0, path.lastIndexOf("\\"));
		}
		return dir;
	}
	
	public static String retrieveFileName(String path) {
		String fileName = path;
		if (path.contains("/")) {
			fileName = path.substring(path.lastIndexOf("/") + 1);
		} else if (path.contains("\\")) {
			fileName = path.substring(path.lastIndexOf("\\") + 1);
		}
		return fileName;
	}
	
	public static String getDate() {
		SimpleDateFormat formatter = new SimpleDateFormat("yyyy_MMdd");
		return formatter.format(new Date());
	}
	
}
