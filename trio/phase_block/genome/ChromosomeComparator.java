package genome;

import java.util.Comparator;

public class ChromosomeComparator implements Comparator<Chromosome> {


	@Override
	public int compare(Chromosome chr1, Chromosome chr2) {
		if(chr1.compareTo(chr2) < 0)	return -1;
		else if(chr1.compareTo(chr2) > 1)	return 1;
		return 0;
	}
	
	
}
