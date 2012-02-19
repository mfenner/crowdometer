# Analysis of crowdometer results: tweets by author/publisher of paper
# Version 1.0, 02/19/12
# by Martin Fenner <fenner.martin@mh-hannover.de>

# Import crowdometer result set from figshare
#tweets <- read.csv("http://figshare.com/media/download/97336/89546", sep=",")
classifications <- read.csv("http://figshare.com/media/download/97336/89547", sep=",")

# Combine classifications with tweets, using max value. This will return true
# if at least 50% of classifications are true
results <- unstack(classifications, form=shares_author~tweet_id)
results <- lapply(results, max)

# Get a vector of the results, turn into table that counts all results
results <- table(unlist(results, use.names=FALSE))

# Subtitle
piesubtitle <- sprintf("%3.0f Tweets", sum(results))

# Create label
pielabels <- sprintf("%s (%2.0f%s)", names(results), 100*results/sum(results), "%")

# Load color palette
library(RColorBrewer)
colors = brewer.pal(3, "Blues")

# Do the plotting
opar <- par(mar=c(4,2,2,2), cex.sub=0.8, cex.main=1.4, fg="black", col.main="#25679a")
pie(results, labels=pielabels, col=colors, init.angle=130, cex=0.8, lty=1)
title(main="Tweets by Author/Publisher of Paper", sub=piesubtitle, line=-1)
par(opar)