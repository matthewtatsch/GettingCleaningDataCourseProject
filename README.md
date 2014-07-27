---
Title: Download and transform UCI HAR dataset
Author: Matthew Tatsch
Date: July 27, 2014
---
# Download and transform UCI HAR dataset
Coursera x Johns Hopkins "Getting and Cleaning Data" course project.

## Overview

The run-analysis.R script performs actions on the UCI Human Activity Recognition Using Smartphone Data Set detailed as follows.  No preparation is required, but it is assumed that the data set will be available via [this location](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip).  In addition to the *README.txt* file included in the dataset, the *features_info.txt* file contains a description of the measures obtained.  Further information about the data set can be found at the [UCI Machine Learning Repository](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones). 

## Downloading and Extracting the Data
The following steps are taken to download and extract the data:

1. A directory called "data" is created in the working directory (if it does not already exist).
2. The *.zip UCI Human Activity Recognition data set is downloaded from its online repository into a temporary file.
3. The contents of the data set are extracted to the data directory created in step 1.

## A Note on the Files' Relations
The data set contains several files, related to one another as follows (note that the following explanation refers to training data, but that the same relationships apply to the test data):

* *X_train.txt* contains the various acclerometer measures obtained during a single observation of a subject during a particular activity.
* *y_train.txt* contains activity IDs corresponding to each observation in *X_train.txt*.
* *subject_train.txt* contains the ID for the subject in each observation in *X_train.txt*.

In addition to the *train* and *test* sets, the following files provide additional descriptive information about the measures and observations:

* *features.txt* provides abbreviated descriptive labels for the data in the *X_[...].txt* files.  These descriptive labels can effectively be thought of as column headers for the *X_[...].txt* files.
* *activity_labels.txt* lists the ID and description for the six activities observed.  The integer values in this file correspond to the values in the *y_[...].txt* files.

## Preparing the Data for Transformation
The script then loads several portions of the dataset into various data frames to prepare it for further processing:

1. The *activity_labels.txt* file is loaded into the `activities` data frame.
2. The *features.txt* file is loaded into the `features` data frame
3. The *subject_train.txt* and *subject_test.txt* files are loaded into the `subject_train` and `subject_test` data frames, respectively, and are subsequently combined into a single `subject` data frame.  **NOTE:** It is important to understand that the train and test data sets are combined in that order, hence `subject <- rbind(subject_train,subject_test)`.
4. The *activity_train.txt* and *activity_test.txt* files are loaded into the `activity_train` and `activity_test` data frames, respectively, and are subsequently combined into a single `activity` data frame (again, in the order of train and then test).
5. The *measure_train.txt* and *measure_test.txt* files are loaded into the `measure_train` and `measure_test` data frames, respectively, and are subsequently combined into a single `measure` data frame.

## Identifying the Mean and Standard Deviation Measures
Next, the script examines the `features` data frame to find features containing either "mean()" or "std()" as these features represent mean and standard deviation, respectively, for the corresponding measure.  Both the indices and values of the matched features are combined into the data frame `matchedCols` for later use in extracting these features from `measure`.

```R
matchPatterns <- c("mean\\(\\)","std\\(\\)")
matchedColIndices <- grep(paste(matchPatterns, collapse = "|"), features[[2]])
matchedColNames <- grep(paste(matchPatterns, collapse = "|"), features[[2]],
                        value = TRUE)
matchedCols <- cbind.data.frame(matchedColIndices,matchedColNames,
                                stringsAsFactors = FALSE)
```

## Renaming Feature Names
The names used in *features.txt* are heavily abbreviated, so in order to make them more readable, several transformations are performed on the values in the `matchedCols` data frame (which, again, is what will be used to eventually extract and name the measure in our final tidy data set):

Some features contained the erroneous label, "BodyBody":
```R
matchedCols[[2]] <- sub("BodyBody","Body",matchedCols[[2]])
```

Replaced leading "t"s with "Time" and "f"s with "Freq" to indicate the domain of the measurement:
```R
matchedCols[grep("^t",matchedCols$matchedColNames),2] <- 
     sub("t","Time",matchedCols[grep("^t",matchedCols$matchedColNames),2])
matchedCols[grep("^f",matchedCols$matchedColNames),2] <- sub("f","Freq",
     matchedCols[grep("^f",matchedCols$matchedColNames),2])
```

Replaced "Acc" with "Accelerometer", "Gyro" with "Gyroscope", and "Mag" with "Magnitude":
```R
matchedCols[[2]] <- sub("Acc","Accelerometer",matchedCols[[2]])
matchedCols[[2]] <- sub("Gyro","Gyroscope",matchedCols[[2]])
matchedCols[[2]] <- sub("Mag","Magnitude",matchedCols[[2]])
```

Replaced "mean()" with "Mean" and "std()" with "SD" (APA abbreviation for "standard deviation"):
```R
matchedCols[[2]] <- sub("mean\\(\\)","Mean",matchedCols[[2]])
matchedCols[[2]] <- sub("std\\(\\)","SD",matchedCols[[2]])
```

Finally, replaced references to "X", "Y", or "Z" with the more descriptive "[XYZ]-Axis" in order to clearly indicate to what these letters refer:
```R
matchedCols[[2]] <- sub("X","X-Axis",matchedCols[[2]])
matchedCols[[2]] <- sub("Y","Y-Axis",matchedCols[[2]])
matchedCols[[2]] <- sub("Z","Z-Axis",matchedCols[[2]])
```

## Extracting the Desired Measures
The next step is for the script to extract from `measure` into a new data frame, `humanActRec`, only those values we identified via `matchedCols`.  This is done by using `matchedCols$matchedColIndices` to identify the column indices in `measure`:
```R
humanActRec <- measure[matchedCols$matchedColIndices]
```

Next the script adds the corresponding, transformed feature names:

```R
names(humanActRec) <- matchedCols$matchedColNames
```

## Adding Activity and Subject Data
In order to arrive at a complete data set wherein each row contains the subject, activity, and measures for a single observation, the script uses `cbind.data.frame()` to combine `subject`, `activity`, and the newly-created `humanActRec`.

The script then makes use of `merge()` to bring in the descriptive names from `activities`:

```R
humanActRec <- merge(activities, humanActRec)
```

**NOTE:** It is important to recognize that `merge()` should only be used after `subject`, `activity`, and `humanActRec` are combined into a single data frame, as `merge()` may change the data's sort order.

Finally, in order for `humanActRec$Subject` to be used in our aggregation step, we convert it to a factor:

```R
humanActRec$Subject <- as.factor(humanActRec$Subject)
```

## A Tidy Data Set of Averages
The last step of the script is to create a new data frame containing the average value of each measure for each subject and activity:

```R
humanActRecAvg <- aggregate(humanActRec[3:length(humanActRec[2,])],
                            list(Subject = humanActRec$Subject, 
                                 Activity = humanActRec$Activity),
                            mean)
```

Finally, the script writes the tidy data set to a comma separated file in the current working directory via use of `write.table()`.
