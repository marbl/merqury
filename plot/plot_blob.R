#!/usr/bin/env Rscript

require("argparse")
require("ggplot2")
require("scales")

parser <- ArgumentParser(description = "Make blob plots.")
parser$add_argument("-f", "--file", type="character", help=".count tdf; with headers; ie. <category> <seqId> <hap1Count> <hap2Count> <seqSize> (required)", default=NULL)
parser$add_argument("-o", "--output", type="character", default="hapmers.blob", help="output prefix [default %(default)s]")
parser$add_argument("-x", "--xdim", type="double", default=6.5, help="width of output plot [default %(default)s]")
parser$add_argument("-y", "--ydim", type="double", default=6, help="height of output plot [default %(default)s]")
args <- parser$parse_args()

blob_plot <- function(dat, out, w=6.5, h=6) {

  dat=read.table(dat, header=TRUE)

  max_total=max(max(dat[,3]), max(dat[,4])) * 1.01
  col_lab=names(dat)[1]
  x_lab=names(dat)[3]
  y_lab=names(dat)[4]
  print(x_lab)
  print(y_lab)

  ggplot(dat, aes(x=dat[,3], y=dat[,4], color=dat[,1], size=dat[,5])) +
    geom_point(shape=16) + theme_bw() +
    scale_color_brewer(palette = "Set1") +
    scale_fill_brewer(palette = "Set1") +     # Set1 -> Red / Blue. Set2 -> Green / Orange.
    scale_x_continuous(labels=comma, limits = c(0, max_total)) +
    scale_y_continuous(labels=comma, limits = c(0, max_total)) +
    scale_size_continuous(labels=comma, range = c(1, 10), name = "Total k-mers") +
    theme(legend.text = element_text(size=11),
          legend.position = c(0.83,0.70),  # Modify this if the legend is covering your favorite circle
          legend.background = element_rect(size=0.5, linetype="solid", colour ="black"),
          axis.title=element_text(size=14,face="bold"),
          axis.text=element_text(size=12, face="bold")) +
    guides( size = guide_legend(order = 1),
            colour = guide_legend(override.aes = list(size=5), order = 2, title = col_lab)) +
    xlab(x_lab) + ylab(y_lab)
  
  ggsave(file = paste(out, '.png', sep=""), height = h, width = w)
  ggsave(file = paste(out, '.pdf', sep=""), height = 2*h, width = 2*w)

}

blob_plot(args$file, args$output, args$xdim, args$ydim)

