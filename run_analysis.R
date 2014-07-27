##   This file delivers all functions and code needed to meet the requirements
##   for the Coursera "Getting and Cleaning Data" course project (details at
##   https://class.coursera.org/getdata-005/human_grading).
##
##   Specifically, this program will download the "UCI HAR Dataset" and create
##   a tidy data set providing the averages of the mean and standard deviation
##   measures for each subject and activity.

# url where data is stored
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
datadir <- "data/"                                          # local dir to store data
UCIdir <- "UCI HAR Dataset/"                                # top-level folder in zip file
tFile <- tempfile(tmpdir = ".")                             # Create temp file for zip
tidyFileName <- "Human_Activity_Recognition_Averages.csv"   # File name to write tidy data to

# create datadir if not exists
if (!file.exists(datadir)){
     dir.create(datadir)           
}

# download zip and extract contents to datadir
message(paste0("Downloading data from ", url, "..."))
download.file(url, destfile = tFile, method = "curl", quiet = TRUE)
unzip(tFile, exdir = datadir)
unlink(tFile)

message("Reading data...")

# get activity labels and features list 
activities <- read.table(paste0(datadir, UCIdir, "activity_labels.txt"),
                         col.names = c("ActivityID", "Activity"))
features <- read.table(paste0(datadir, UCIdir, "features.txt"),
                       colClasses = c("numeric", "character"),
                       stringsAsFactors = FALSE)

# get subject data and rbind into single subject data frame
subject_train <- read.table(paste0(datadir, UCIdir, "train/subject_train.txt"))
subject_test <- read.table(paste0(datadir, UCIdir, "test/subject_test.txt"))
subject <- rbind(subject_train,subject_test)
names(subject) <- c("Subject")
rm(subject_train, subject_test)

# get activity data and rbind into single data frame, merge with activity descr
activity_train <- read.table(paste0(datadir, UCIdir, "train/y_train.txt"))
activity_test <- read.table(paste0(datadir, UCIdir, "test/y_test.txt"))
activity <- rbind(activity_train,activity_test)
names(activity) <- c("ActivityID")
rm(activity_train,activity_test)

# get measures data and rbind into single measures data frame
measure_train <- read.table(paste0(datadir, UCIdir, "train/X_train.txt"))
measure_test <- read.table(paste0(datadir, UCIdir, "test/X_test.txt"))
measure <- rbind(measure_train,measure_test)
rm(measure_train,measure_test)

# Use grep to identify only the measures we are interested in, and create a
# data frame of the indices (for later use in extracting columns) and names
matchPatterns <- c("mean\\(\\)","std\\(\\)")	# mean and standard dev patterns
matchedColIndices <- grep(paste(matchPatterns, collapse = "|"), features[[2]])
matchedColNames <- grep(paste(matchPatterns, collapse = "|"), features[[2]],
                        value = TRUE)
matchedCols <- cbind.data.frame(matchedColIndices,matchedColNames,
                                stringsAsFactors = FALSE)

# transform column names to be more descriptive
message("Renaming columns...")

# clean up "BodyBody"
matchedCols[[2]] <- sub("BodyBody","Body",matchedCols[[2]])

# replace leading "t"s -> "Time", leading "f"s -> "Freq"
matchedCols[grep("^t",matchedCols$matchedColNames),2] <- sub("t","Time",
     matchedCols[grep("^t",matchedCols$matchedColNames),2])
matchedCols[grep("^f",matchedCols$matchedColNames),2] <- sub("f","Freq",
     matchedCols[grep("^f",matchedCols$matchedColNames),2])

# replace "Acc" -> "Accelerometer", "Gyro" -> "Gyroscope", "Mag" -> "Magnitude"
matchedCols[[2]] <- sub("Acc","Accelerometer",matchedCols[[2]])
matchedCols[[2]] <- sub("Gyro","Gyroscope",matchedCols[[2]])
matchedCols[[2]] <- sub("Mag","Magnitude",matchedCols[[2]])

# replace "mean()" -> "Mean", "std()" -> "SD" (APA abbrev. for Standard Deviation)
matchedCols[[2]] <- sub("mean\\(\\)","Mean",matchedCols[[2]])
matchedCols[[2]] <- sub("std\\(\\)","SD",matchedCols[[2]])

# replace "[XYZ]"s -> "[XYZ]-axis"
matchedCols[[2]] <- sub("X","X-Axis",matchedCols[[2]])
matchedCols[[2]] <- sub("Y","Y-Axis",matchedCols[[2]])
matchedCols[[2]] <- sub("Z","Z-Axis",matchedCols[[2]])

message("Extracting Mean and SD measures...")

# extract from measure only those columns identified by matchedCols, add names
humanActRec <- measure[matchedCols$matchedColIndices]
names(humanActRec) <- matchedCols$matchedColNames

# add activity and subject data
humanActRec <- cbind.data.frame(activity, subject, humanActRec)

# bring in activity descriptions and drop ActivityID
humanActRec <- merge(activities, humanActRec)
humanActRec$ActivityID <- NULL

# convert Subject to factor
humanActRec$Subject <- as.factor(humanActRec$Subject)

# Create a second, independent tidy data set with the average of each variable 
# for each activity and each subject.
message(paste0("Writing averages to ", getwd(), "/", tidyFileName, "..."))
humanActRecAvg <- aggregate(humanActRec[3:length(humanActRec[2,])],
                            list(Subject = humanActRec$Subject, 
                                 Activity = humanActRec$Activity),
                            mean)

# write data to file
write.table(humanActRecAvg, tidyFileName, sep = ",", row.names = FALSE)

message("Done!")