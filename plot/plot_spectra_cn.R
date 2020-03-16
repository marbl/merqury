#!/usr/bin/env Rscript

require("argparse")
require("ggplot2")
require("scales")

parser <- ArgumentParser(description = "Make spectra-cn plots. Line, filled, and stacked spectra-cn plots will be generated.")
parser$add_argument("-f", "--file", type="character", help=".spectra-cn.hist file (required)", default=NULL)
parser$add_argument("-o", "--output", type="character", help="output prefix (required)")
parser$add_argument("-z", "--zero-hist", type="character", default="", help=".only.hist file (optional, assembly only counts)")
parser$add_argument("-l", "--cutoff", type="character", default="", help="cutoff.txt file (optional, solid k-mer cutoffs)")
parser$add_argument("-x", "--xdim", type="double", default=6, help="width of plot [default %(default)s]")
parser$add_argument("-y", "--ydim", type="double", default=5, help="height of plot [default %(default)s]")
parser$add_argument("-m", "--xmax", type="integer", default=0, help="maximum limit for k-mer multiplicity [default (x where y=peak) * 2.1]")
parser$add_argument("-n", "--ymax", type="integer", default=0, help="maximum limit for k-mer count [default (y where y=peak) * 1.1]")
parser$add_argument("-t", "--type", type="character", default="all", help="available types: line, fill, stack, or all. [default %(default)s]")
parser$add_argument("-p", "--pdf", dest='pdf', default=FALSE, action='store_true', help="get output in .pdf. [default .png]")
args <- parser$parse_args()

gray = "black"
red = "#E41A1C"
blue = "#377EB8" # light blue = "#56B4E9"
green = "#4DAF4A"
purple = "#984EA3"  # purple = "#CC79A7"
orange = "#FF7F00"  # orange = "#E69F00"
yellow = "#FFFF33"

merqury_col = c(gray, red, blue, green, purple, orange)
merqury_brw <- function(dat, direction=1) {
  merqury_colors=merqury_col[1:length(unique(dat))]
  if (direction == -1) {
    merqury_colors=rev(merqury_colors)
  }
  merqury_colors
}

ALPHA=0.4
LINE_SIZE=0.3

fancy_scientific <- function(d) {
  # turn in to character string in scientific notation
  d <- format(d, scientific = TRUE)
  # quote the part before the exponent to keep all the digits and turn the 'e+' into 10^ format
  d <- gsub("^(.*)e\\+", "'\\1'%*%10^", d)
  # convert 0x10^00 to 0
  d <- gsub("\\'0[\\.0]*\\'(.*)", "'0'", d)
  # return this as an expression
  parse(text=d)
}

plot_zero_line <- function(zero) {
  if (!is.null(zero)) {
    if (length(zero[,1]) == 1) {
      scale_fill_manual(values = c(red), name="k-mer")
    } else if (length(zero[,1]) == 2) {
      scale_fill_manual(values = c(blue, red), name="k-mer")
    } else if (length(zero[,1]) == 3) {
      scale_fill_manual(values = c(purple, blue, red), name="k-mer")
    } else {
      scale_fill_manual(values = merqury_brw(zero[,1]), name="k-mer")
    }
  }
}

plot_cutoff <- function(cutoff) {
  if (!is.null(cutoff)) {
    geom_vline(data = cutoff, aes(xintercept = cutoff[,2], colour = cutoff[,1]), show.legend = FALSE, linetype="dashed", size=LINE_SIZE)
  }
}

plot_zero_fill <- function(zero) {
  if (!is.null(zero)) {
    geom_bar(data=zero, aes(x=zero[,2], y=zero[,3], fill=zero[,1], colour=zero[,1], group=zero[,1]),
      position="stack", stat="identity", show.legend = FALSE, width = 2, alpha=ALPHA)
  }
}

plot_zero_stack <- function(zero) {
  if (!is.null(zero)) {
    geom_bar(data=zero, aes(x=zero[,2], y=zero[,3], fill=zero[,1], colour=zero[,1]),
      position="stack", stat="identity", show.legend = FALSE, width = 2, alpha=ALPHA)
  }
}

format_theme <- function() {
    theme(legend.text = element_text(size=11),
          legend.position = c(0.95,0.95),  # Modify this if the legend is covering your favorite circle
          legend.background = element_rect(size=0.1, linetype="solid", colour ="black"),
          legend.box.just = "right",
          legend.justification = c("right", "top"),
          axis.title=element_text(size=14,face="bold"),
          axis.text=element_text(size=12))
}

plot_line <- function(dat, name, x_max, y_max, zero, cutoff) {
  ggplot(data=dat, aes(x=kmer_multiplicity, y=Count, group=dat[,1], colour=dat[,1])) +
    geom_line() +
    scale_color_manual(values = merqury_brw(dat[,1]), name="k-mer") +
    plot_zero_line(zero=zero) +
    plot_zero_fill(zero=zero) +
    plot_cutoff(cutoff) +
    theme_bw() +
    format_theme() +
    scale_y_continuous(labels=fancy_scientific) +
    coord_cartesian(xlim=c(0,x_max), ylim=c(0,y_max))
}

plot_fill <- function(dat, name, x_max, y_max, zero, cutoff) {
  ggplot(data=dat, aes(x=kmer_multiplicity, y=Count)) +
    geom_ribbon(aes(ymin=0, ymax=pmax(Count,0), fill=dat[,1], colour=dat[,1]), alpha=ALPHA, linetype=1) +
    plot_zero_fill(zero=zero) +
    plot_cutoff(cutoff) +
    theme_bw() +
    format_theme() +
    scale_color_manual(values = merqury_brw(dat[,1]), name="k-mer") +
    scale_fill_manual(values = merqury_brw(dat[,1]), name="k-mer") +
    scale_y_continuous(labels=fancy_scientific) +
    coord_cartesian(xlim=c(0,x_max), ylim=c(0,y_max))
}

plot_stack <- function(dat, name, x_max, y_max, zero, cutoff) {
  dat[,1]=factor(dat[,1], levels=rev(levels(dat[,1]))) #[c(4,3,2,1)] reverse the order to stack from read-only
  ggplot(data=dat, aes(x=kmer_multiplicity, y=Count, fill=dat[,1], colour=dat[,1])) +
    geom_area(size=LINE_SIZE , alpha=ALPHA) +
    plot_zero_stack(zero=zero) +
    plot_cutoff(cutoff) +
    theme_bw() +
    format_theme() +
    scale_color_manual(values = merqury_brw(dat[,1], direction=1), name="k-mer", breaks=rev(levels(dat[,1]))) +
    scale_fill_manual(values = merqury_brw(dat[,1], direction=1), name="k-mer", breaks=rev(levels(dat[,1]))) +
    scale_y_continuous(labels=fancy_scientific) +
    coord_cartesian(xlim=c(0,x_max), ylim=c(0,y_max))
}

save_plot <- function(name, type, outformat, h, w) {
  ggsave(file = paste(name, type, outformat, sep = "."), height = h, width = w)
}

spectra_cn_plot  <-  function(hist, name, zero="", cutoff="", w=6, h=4.5, x_max, y_max, type="all", pdf=FALSE) {
  # Read hist
  dat=read.table(hist, header=TRUE)
  dat[,1]=factor(dat[,1], levels=unique(dat[,1]), ordered=TRUE) # Lock in the order
  
  # Read asm-only
  dat_0 = NULL
  if (zero != "") {
    dat_0=read.table(zero, header=FALSE)
    dat_0[,1]=as.factor(dat_0[,1])
    dat_0[,1]=factor(dat_0[,1], levels=rev(unique(dat_0[,1])), ordered=TRUE)
  }

  # Read cutoffs
  dat_cut = NULL
  if (cutoff != "") {
    dat_cut=read.table(cutoff, header = FALSE)
    dat_cut[,1]=as.factor(dat_cut[,1])
    dat_cut[,1]=factor(dat_cut[,1], levels=unique(dat_cut[,1]), ordered=TRUE)
  }

  # x and y max
  y_max_given=TRUE;
  if (y_max == 0) {
    y_max=max(dat[dat[,1]!="read-total" & dat[,1]!="read-only" & dat[,2] > 3,]$Count)
    y_max_given=FALSE;
  }
  if (x_max == 0) {
    x_max=dat[dat[,3]==y_max,]$kmer_multiplicity
    x_max=x_max*2.5
  }
  if (! y_max_given) {
    y_max=y_max*1.1
  }
  print(paste("x_max:", x_max, sep=" "))
  if (zero != "") {
    y_max=max(y_max, sum(dat_0[,3]*1.1))	# Check once more when dat_0 is available
  }
  print(paste("y_max:", y_max, sep=" "))

  outformat="png"
  if (pdf) {
    outformat="pdf"
  }
  
  if (type == "all" || type == "line") {
    print("## Line graph")
    plot_line(dat, name, x_max, y_max, zero = dat_0, cutoff = dat_cut)
    save_plot(name=name, type="ln", outformat, h=h, w=w)
  }
  
  if (type == "all" || type == "fill") {
    print("## Area under the curve filled")
    plot_fill(dat, name, x_max, y_max, zero = dat_0, cutoff = dat_cut)
    save_plot(name=name, type="fl", outformat, h=h, w=w)
  }
  
  if (type == "all" || type == "stack") {
    print("## Stacked")
    plot_stack(dat, name, x_max, y_max, zero = dat_0, cutoff = dat_cut)
    save_plot(name=name, type="st", outformat, h=h, w=w)
  }
}

spectra_cn_plot(hist = args$file, name = args$output, zero = args$zero, cutoff = args$cutoff, h = args$ydim, w = args$xdim, x_max = args$xmax, y_max = args$ymax, type = args$type, pdf = args$pdf)


