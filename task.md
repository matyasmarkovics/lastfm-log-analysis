# RESTful Log Analysis Service

This task is intended for Data Engineer or Senior Data Engineer position candidates.

_Author: Waclaw Kusnierczyk, [waclaw.kusnierczyk@adform.com](mailto:waclaw.kusnierczyk@adform.com)_  
_Last edit: 15 March, 2016_


## Task specifications

Your task is to build a simple RESTful service that will allow the user to:

   * **upload** data;
   * **execute queries** to obtain summaries from the uploaded data.

Instead of uploading data through the REST API, you are free to provide some other way of feeding the system.

Please use the [example dataset](http://mtg.upf.edu/static/datasets/last.fm/lastfm-dataset-1K.tar.gz) from [Last.fm](Last.fm).
Investigate the files to gain insight into the format and content.
If you have difficulty handling the dataset on your machine, you may truncate the file so that it is easier to test.
Consider having a look at a small [mock dataset](https://gist.github.com/eshioji/30b9cdb95aecb5981749) that you can also use for testing.

It is up to you whether the user will be able to feed data from local files or directly from a URL.
(Note that the files for the example data set are provided in a gzipped tar archive, so if you want to use the provided URL directly, your system will need to handle decompression.)

The service should **provide endpoints** for executing the following queries:

   1. List of all unique users.
   2. List of _n_ top users and the number of distinct songs played by each of them, sorted in decreasing order by the number of distinct songs (i.e., the user with the highest number of distinct songs listened appearing at the top of the list).
   3. List of _n_ top most frequently listened songs and the number of times each of them was played, sorted in decreasing order by the number of times a song was played.
   4. List of _n_ top longest listening sessions, with information on their duration, the user, and the songs listened, sorted decreasingly by session length.
   
The user should be able to provide _n_ (an arbitrary limit on the number of items to be returned) while sending a query.
You do not need to include any actual results in your delivery, just make sure that your service is able to provide them when executed.

For this task, a **session** is defined as one or more songs played by a particular user, where each song is started within 20 minutes of the previous song's start time.

It is up to you whether the service is to be run locally or in the cloud.
If you choose a cloud-based solution, make sure it will not require setting up a new account, paid or free.
In either case, it should be possible to query the service with a command line tool like `curl`.

It is up to you how the result from a query will be formatted (`html`, `xml`, `json`, `csv`, etc).

Your **delivery should contain** the following:

   * **Complete source code** with a build file.  Keep it simple.
   * All necessary **dependencies** that are not handled by the build system (e.g., are not downloadable from maven central).
   * **Concise description** of the solution.
   * **Discussion** of your choice of technology (programming language, libraries, frameworks, APIs etc.).
   * **Instructions** on how to build, test, deploy, and execute (query) the service.  At least unit tests for the most important functionality should be included.
   * **Discussion** of unsolved problems and shortcomings of your solution.  Is your solution scalable?
   
It is up to you whether the delivery is in the form of a single archive, a link to a version-controlled repository, etc.
 
We are looking for your **ability to deliver** a minimal working solution to a given task.
Don't worry if you cannot solve all the problems, but please discuss difficulties if you have any.
If anything above is unclear to you, please ask. 

### Optional

Provide endpoints for executing the following queries:

   1. Given a user ID, **predict** the next time the user will be listening to any content.)
   2. Given a user ID, **predict** the next song(s) the user will be listening to.
   3. Given a user ID, **recommend** songs (or artists) that the user has not listened to yet, but might want to.

If you're not able to implement these, please at least provide some ideas for how you might do it---what kind of patterns you would be looking at, what algorithms/tools you would use (e.g., machine learning or recommender systems).


## Datasets

   * [http://mtg.upf.edu/static/datasets/last.fm/lastfm-dataset-1K.tar.gz](http://mtg.upf.edu/static/datasets/last.fm/lastfm-dataset-1K.tar.gz)
   * [https://gist.github.com/eshioji/30b9cdb95aecb5981749](https://gist.github.com/eshioji/30b9cdb95aecb5981749)
