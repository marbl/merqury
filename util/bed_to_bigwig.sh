#!/bin/bash

if [[ -z $1 ]]; then
    echo "Usage: ./bed_to_bigWig.sh <bed> <asm.fai> <convert_pipes>"
    echo -e "\t<bed>: ex. out.asm.mat.inherited.bed"
    echo -e "\t<asm.fai>: generate with samtools faidx"
    echo -e "\t<convert_pipes>: convert | to _ by default. Set to F if not wanted."
    exit 0
fi

bed=$1
fai=$2
convert=$3

module load bedtools
module load ucsc/406

bg=${bed/.bed/.bg}
sizes=${fai/.fai/.sizes}
cat $fai | cut -f1-2 > $sizes

if [[ "$convert" = "F" ]]; then
  echo "# Convert to bigBed"
  cat $bed | bedtools genomecov -bg -g $sizes -i - > $bg
else
  echo "# Convert to bigBed, removing pipes"
  sed -i 's/|/_/g' $sizes
  cat $bed | sed 's/|/_/g' | bedtools genomecov -bg -g $sizes -i - > $bg
fi

sort=${bg/.bg/.srt.bg}
cut -f1 $sizes | sort -k 1,1 > $sizes.order
echo "
# Re-sort in alphabetical order so that the ucsc tools understands it"
for sq in $(cat $sizes.order)
do
  echo "  $sq"
  awk -v sq=$sq '$1==sq' $bg >> $sort
done

echo "
# Convert $sort to $bw"
bw=`echo $bed | sed 's/.bed$/.bigwig/g'`
bedGraphToBigWig $sort $sizes $bw

echo "
# Done! To cleaning up intermediate files, run:
rm $bg $sort"


