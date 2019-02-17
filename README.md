## Calibration App Question Database

This repository contains the source code and tools to manage the questions
database for the Open Philanthropy Calibration app.

## Overview of the database

The calibration app is implemented as a CouchDB database, which stores
JSON documents. The CouchDB database is hosted on Cloudant (owned by IBM), a CouchDB
service provider. For account holders, the database can be accessed by logging in at:

https://console.bluemix.net

then choosing "Cloud Foundry", then "Public", then "calibration-app" and finally "Launch". 

Each question set is a separate database, all within the same account.
Each question set database holds both the questions it pulls from in order
to quiz users, and the users of that data set. The databases storing
question data are:

* `city_population`
* `confidence_interval`
* `irc_trivia`
* `politifact`
* `scatterplot_correlation`
* `simple_math`

These are the valid values to use when a tool requires that you select
a question set.

There is another database, `answers`, which holds the log of all the
answers users have given to questions the app has presented them.

## Tools for working with the data

Manipulating the questions stored in the database is done through the
command line, through several simple utilities provided in the `scripts/`
directory, namely:

1. `search` -- finds the database identifier and unique ID of a question
   given its exact text

1. `delete` -- deletes a question from a question set given its database
   identifier

1. `upload` -- uploads questions stored locally in a file in JSON format
   to a given question set (can be used to add new questions or edit
   multiple questions at once)

1. `autonumber` -- given a file with an array of JSON documents and
   a starting number, numbers the documents sequentially by assigning
   them an `_id` property corresponding to their position in the array
   relative to the given starting number (useful when adding new questions
   to a data set)


### Platform requirements

These tools are designed to run within a standard bash shell. Any system
that can run bash and install the software outlined in the next section
should work.

### Required software

This is a list of software that needs to be installed for the utilities
included to run. Please refer to the documentation of each piece of
software to get installation instructions for your platform:

1. [CouchApp](https://github.com/couchapp/couchapp) (requires Python >=
   2.6, < 3) -- utilities for deploying CouchDB applications

1. [jq](https://stedolan.github.io/jq/) -- a lightweight and flexible
   command-line JSON processor

### How to use the tools included

All of the tools used to change the questions used by the calibration app
are meant to be executed from the command line, from this directory's root
repository. There is risk of things breaking if you run them from any
other directory, since some of them rely on the underlying source code,
and they need to know where to find it.

In short, you should be running `./scripts/COMMAND`. Examples:

```
./scripts/search ...
./scripts/delete ...
./scripts/upload ...
```

The majority of the tools run queries against CouchDB, so most of the time
you'll be required to enter the password for the Cloudant account that's
been set up for Open Philanthropy.

#### Using `search`

The `search` command is how you figure out the database identifier of
a question, which is something the other commands will need in order to do
their work.

You need to provide `search` with the question set you want to look in and
the exact texts of the questions you're interested in.

Usage:

```
./scripts/search -s question_set question_text_1 question_text_2 ...
```

**Example**

If we want to search the confidence interval question set for the question
"What year saw the death of Terry Frost?", we'd issue the following
command:

```
./scripts/search -s confidence_interval  "What year saw the death of Terry Frost?"
``` 

After pressing enter, we'll be asked for the Cloudant password. When we
type it in and hit enter, we'll get the results. This is what the output
will look like:

```
Searching confidence_interval...
Enter host password for user 'openphil':
{"docs":[
{"_id":"10","questionID":465463037303749}
],
"bookmark": "g1AAAAA0eJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYkbGoBkOGAyULEsAGPADXs",
"warning": "no matching index found, create an index to optimize query time"}
```

The `_id` attribute of the first documents returned in `docs` is the
database identifier of the question with the matching text in the
database.

`search` can also handle looking up several questions at once. If you pass
in multiple questions, you'll get the `_id` of each in the response, like
this:

```
./scripts/search -s confidence_interval  "What year saw the death of Terry Frost?" "A scrum half in rugby union would traditionally wear which number on his back?" "In what year were restrictor plates implemented in NASCAR?"
Searching confidence_interval...
Enter host password for user 'openphil':
{"docs":[
{"_id":"10","questionID":465463037303749},
{"_id":"1008","questionID":125198229020548},
{"_id":"115","questionID":358760597933542}
],
"bookmark": "g1AAAAA2eJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYozGxqagqQ4YFIwwSwAfiwN6Q",
"warning": "no matching index found, create an index to optimize query time"}
```

#### Using `delete`

The `delete` command allows you to delete a question from a question set.

In order to do this, it needs to be given the question set to delete from
and the database identifiers of each question you want removed (see
`search` for how to find those out).

Here's an example:

```
./scripts/delete -s simple_math 3 4 10
Deleting from simple_math: {"ids":["3","4","10"]}
Cloudant password:
Updating user 9f60eb615584944d0be71fe7ca01b9ec
{"ok":true}
Updating user base_user
{"ok":true}
```

*NOTE:* The more people have used the question set you're deleting from,
the longer the command will take to complete and the more output it will
produce.

#### Using `upload`

The `upload` command allows you to either add new questions to a question
set, or change existing questions.

You need to provide two things for this to work:

- the question set you want to change questions in or add questions to,
  specified through the `-s` option
- the path to a file containing a JSON array of the documents,
  representing the questions you are adding or editing

Here's an example usage:

```
upload -s simple_math my_new_simple_math_questions.json
```

The first step when adding or changing questions in a given question set is to
build the file that contains the question data. The file has to contain a JSON
array of objects, each representing a question with all the attributes
necessary to display it to the user and log it after they've answered it.
Here's an example of such a file:

```
[
  {
    "text": "How many breeds of dog does the Kennel Club recognise?",
    "subCategory": "Animals",
    "answerScale": "linear",
    "minAnswers": 1,
    "explanation": "The correct answer is 195.",
    "maxAnswers": 1,
    "correctAnswer": 195
  },
  {
    "text": "How many gill slits do the majority of sharks have?",
    "answerScale": "linear",
    "subCategory": "Animals",
    "minAnswers": 1,
    "explanation": "The correct answer is 10.",
    "maxAnswers": 1,
    "correctAnswer": 10
  },
  {
    "text": "How many legs does a lobster have?",
    "answerScale": "linear",
    "subCategory": "Animals",
    "minAnswers": 1,
    "explanation": "The correct answer is 10.",
    "maxAnswers": 1,
    "correctAnswer": 10
  }
]
```

When adding questions, you'll need to build this file manually. When you
just want to change questions that are already in the database, you should
use the `download` tool to initialize the file, and then edit it to suit
your needs (see [Editing existing questions](#editing-existing-questions)).

The fields you should specify for each question are:

- `"text"`: the question text, which is displayed to the user within the app
- `"answerScale"`: tells the app how to evaluate the accuracy of the user's
  answer. When it is possible for the user to guess the exact answer (e.g.
  "How many legs does a lobster have?"), you want to set it to `"linear"`;
  when the only reasonable answer is a ballpark guess (e.g. "How many
  grains of sand are there on Earth?"), you should set it to
  `"exponential"`.
- `"subCategory"`: This is optional, and meant to be used during data
  analysis. You can set it to whatever you think would be useful.
- `"minAnswers"`: The minimum number of answers the user should be
  allowed to give to the question.
- `"maxAnswers"`: The maximum number of answers the user should be
  allowed to give to the question.
- `"correctAnswer"`: The answer the app should accept as correct.
- `"explanation"`: The text that will be shown to the user if they get the
  question wrong. Most questions currently use "The correct answer is _the
  correct answer_."

The most important attribute is the database identifier, `_id`. What its
set to will determine if `upload` will change that particular question, or
add it as a new question to the question set, as we'll cover in [Adding
new questions](#adding-new-questions) and [Editing existing
questions](#editing-existing-questions), respectively.

#### Adding new questions

Before the data you've generated can be uploaded to the database and be
served to users, they need to be assigned a database identifier via the
`_id` field, a unique `questionID` attribute, and a `timeWhenAdded`
time stamp. The commands necessary to do this automatically are provided.

**It is crucial that all questions within each question set have consecutive
`_id`s, and that there are no gaps between the `_id`s**. It's therefore
recommended that you use the `autonumber` tool to assign the `_id`
attributes. It works by taking the input file containing the array of
questions you want to add, and an initial ID, and numbers each question
incrementally starting at the initial ID. 

Once you have the questions you want to add:

1. Find out how many questions the database already contains for the
   question set:

   ```
   curl -s -u openphil https://openphil.cloudant.com/QUESTION_SET/_design/bloom_filter/_view/number_of_questions | jq '.rows[0].value'
   ```

   Here's an example of finding out the number of questions in the
   politifact question set (in this case, 4148):

   ```
   curl -s -u openphil https://openphil.cloudant.com/politifact/_design/bloom_filter/_view/number_of_questions | jq '.rows[0].value'
   Enter host password for user 'openphil':
   4148
   ```

1. Use `autonumber` to assign the `_id` and `questionID` attributes of
   each question, providing the number of questions + 1 as the
   starting ID by issuing:

   ```
   ./scripts/autonumber -i FIRST_ID my_new_questions.json > my_new_questions_numbered.json
   ```

   Continuing with the example with the politifact question set above, you
   should issue the following command:

   ```
   ./scripts/autonumber -i 4149 my_new_questions.json > my_new_questions_numbered.json
   ```

   **NOTE:** The initial ID you use above has to be the total number of
   questions + 1. If the question set contains 10 questions, that means
   there is already a question with an `_id` of 10, so the first of your
   new questions should have an `_id` of 11.

1. Assign a time stamp to each question by running:

   ```
   ./scripts/timestamp my_new_questions_numbered.json > my_new_questions_numbered_timestamped.json
   ```

1. Upload the resulting auto-numbered and timestamped data to the database
   by issuing the following:

   ```
   ./scripts/upload -s QUESTION_SET my_new_questions_numbered_timestamped.json
   ```

Before uploading, ensure that the `_id`s of the questions you're uploading
all follow the `_ids` of the highest-numbered question already present in
the database, and that you're not adding duplicate questions.

#### Editing existing questions

Editing existing questions is similar to adding new ones, except that
you'll be uploading questions that have `_id`s that already exist in the
database. Therefore, there's no need to use `autonumber` to assign them
IDs. The steps to edit a set of questions are the following:

1. Download the questions from the database by issuing:

   ```
   ./scripts/download -s QUESTION_SET id_1 id_2 id_3 ...
   ```

   Here's an example of downloading questions number 1, 115, and 1014 from
   the `confidence_interval` question set and saving the result into
   `questions_to_edit.json`:
 
   ```
   ./scripts/download -s confidence_interval 1 115 1014 > questions_to_edit.json
   ```

1. Open up the file you just created and make your edits. You can edit
   pretty much any attribute you like, except for `_id`, `questionID` and
   `_rev`. When you're done with your edits, save the file, and use
   `upload` to send your changes to the database:

   ```
   ./scripts/upload -s confidence_interval questions_to_edit.json
   ```

Once that completes, you should be able to see your changes reflected
if you download the same questions again.
