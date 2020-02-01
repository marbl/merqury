#!/usr/bin/env Rscript

require("argparse")
require("ggplot2")
require("scales")

parser <- ArgumentParser(description = "Make spectra-cn plots. Line, filled, and stacked spectra-cn plots will be generated.")
parser$add_argument("-f", "--file", type="character", help=".spectra-cn.hist file (required)", default=NULL)
parser$add_argument("-o", "--output", type="character", help="output prefix (required)")
parser$add_argument("-z", "--zero-hist", type="character", default="", help=".only.hist file (optional, shows assembly only counts)")
parser$add_argument("-x", "--xdim", type="double", default=6, help="width of plot [default %(default)s]")
parser$add_argument("-y", "--ydim", type="double", default=3, help="height of plot [default %(default)s]")
parser$add_argument("-m", "--max", type="integer", default=150, help="maximum limit for k-mer multiplicity [default %(default)s]")
parser$add_argument("-t", "--type", type="character", default="all", help="available types: line, fill, stack, or all. [default %(default)s]")
parser$add_argument("-p", "--pdf", dest='pdf', default=FALSE, action='store_true', help="set to get output in .pdf. [default .png]")
args <- parser$parse_args()

plot_zero_line <- function(zero) {
  if (!is.null(zero)) {
if (length(zero[,1]) == 2) {
      scale_fill_manual(values = c("#4DAF4A", "#377EB8"), name="k-mer")
    } else if (length(zero[,1] == 3)) {
      scale_fill_manual(values = c("#984EA3", "#4DAF4A", "#377EB8"), name="k-mer")
    } else {
      scale_fill_brewer(palette = "Set1", direction=1, name="k-mer")
    }
  }
}

plot_zero_fill <- function(zero) {
  if (!is.null(zero)) {
    geom_bar(data=zero, aes(x=zero[,2], y=zero[,3], fill=zero[,1], colour=zero[,1], group=zero[,1]),
      position="stack", stat="identity", show.legend = FALSE, width = 2)
  }
}

plot_zero_stack <- function(zero) {
  if (!is.null(zero)) {
    geom_bar(data=zero, aes(x=zero[,2], y=zero[,3], fill=zero[,1], colour=zero[,1]),
             position="stack", stat="identity", show.legend = FALSE, width = 2)
  }
}

plot_line <- function(dat, name, x_max, y_max, zero) {
  ggplot(data=dat, aes(x=kmer_multiplicity, y=Count, group=dat[,1], colour=dat[,1])) +
    geom_line() +
    scale_color_brewer(palette = "Set1", name="k-mer") +
    plot_zero_line(zero=zero) +
    plot_zero_fill(zero=zero) +
    theme_bw() +
    scale_y_continuous(labels=comma) +
    coord_cartesian(xlim=c(0,x_max), ylim=c(0,y_max))
}

plot_fill <- function(dat, name, x_max, y_max, zero) {
  ggplot(data=dat, aes(x=kmer_multiplicity, y=Count)) +
    geom_ribbon(aes(ymin=0, ymax=pmax(Count,0), fill=dat[,1], colour=dat[,1]), alpha=0.5, linetype=1) +
    plot_zero_fill(zero=zero) +
    theme_bw() +
    scale_color_brewer(palette = "Set1", direction=1, name="k-mer") +
    scale_fill_brewer(palette = "Set1", direction=1, name="k-mer") +
    scale_y_continuous(labels=comma) +
    coord_cartesian(xlim=c(0,x_max), ylim=c(0,y_max))
}

plot_stack <- function(dat, name, x_max, y_max, zero) {
  dat[,1]=factor(dat[,1], levels=rev(levels(dat[,1]))) #[c(4,3,2,1)] reverse the order to stack from read-only
  ggplot(data=dat, aes(x=kmer_multiplicity, y=Count, fill=dat[,1], colour=dat[,1])) +
    geom_area(size=0.2 , alpha=0.8) +
    plot_zero_stack(zero=zero) +
    theme_bw() +
    scale_color_brewer(palette = "Set1", direction=-1, name="k-mer", breaks=rev(levels(dat[,1]))) +
    scale_fill_brewer(palette="Set1", direction=-1, name="k-mer", breaks=rev(levels(dat[,1]))) +
    scale_y_continuous(labels=comma) +
    coord_cartesian(xlim=c(0,x_max), ylim=c(0,y_max))
}

save_plot <- function(name, type, outformat, h, w) {
  ggsave(file = paste(name, 'spectra-cn', type, outformat, sep = "."), height = h, width = w)
}

spectra_cn_plot  <-  function(hist, name, zero="", w=5, h=3, x_max=150, type="all", pdf=FALSE) {
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

  y_max=max(dat[dat[,1]!="read-total" & dat[,1]!="read-only",]$Count)
  y_max=y_max*1.5
  print(paste("y_max:", y_max, sep=" "))

  outformat="png"
  if (pdf) {
    outformat="pdf"
  }
  
  if (type == "all" || type == "line") {
    print("## Line graph")
    plot_line(dat, name, x_max, y_max, zero = dat_0)
    save_plot(name=name, type="ln", outformat, h=h, w=w)
  }
  
  if (type == "all" || type == "fill") {
    print("## Area under the curve filled")
    plot_fill(dat, name, x_max, y_max, zero = dat_0)
    save_plot(name=name, type="fl", outformat, h=h, w=w)
  }
  
  if (type == "all" || type == "stack") {
    print("## Stacked")
    plot_stack(dat, name, x_max, y_max, zero = dat_0)
    save_plot(name=name, type="st", outformat, h=h, w=w)
  }
}

spectra_cn_plot(hist = args$file, name = args$output, zero = args$zero, h = args$ydim, w = args$xdim, x_max = args$max, type = args$type, pdf = args$pdf)


