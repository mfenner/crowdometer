# Analysis of crowdometer results: tweets by author/publisher of paper
# Version 1.0, 02/19/12
# by Martin Fenner <fenner.martin@mh-hannover.de>

# Import crowdometer result set from figshare
# tweets <- read.csv("http://figshare.com/media/download/97336/89546", sep=",")
classifications <- read.csv("http://figshare.com/media/download/97336/89547", sep=",")

author.freq <- table(classifications$shares_author)

# Subtitle
piesubtitle <- sprintf("%3.0f Tweets", sum(author.freq))

# Create label
pielabels <- sprintf("%s (%2.0f%s)", names(author.freq), 100*author.freq/sum(author.freq), "%")

# Load color palette
library(RColorBrewer)
colors = brewer.pal(7, "Blues")

# Do the plotting
opar <- par(mar=c(4,2,2,2), cex.sub=0.8, cex.main=1.4, fg="black", col.main="#25679a")
pie(author.freq, labels=pielabels, col=colors, init.angle=130, cex=0.8, lty=1)
title(main="Tweets by Author/Publisher of Paper", sub=piesubtitle, line=-1)
par(opar)