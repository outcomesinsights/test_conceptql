# Test ConceptQL
These tests validate and/or benchmark the ConceptQL language.

The tests are run using [dbtap](https://github.com/outcomesinsights/dbtap).  The dbtap test files themselves are generated using Ruby's Rake.  See Rake section for more details.


## Structure
- statements
    - Stores ConceptQL statements that are used by both validation and benchmark tests
    - ConceptQL statements live in .rb files
    - Statements are roughly grouped by the node they are testing, e.g. statements/after/\*.rb statements are tests that exercise the "after" node
- validation_statements
    - Stores ConceptQL statements that are used exclusively by validation tests
- benchmark_statements
    - Stores ConceptQL statements that are used exclusively by benchmark tests
- validation_results
    - Stores a set of CSV files in a structure that mirrors the statements directory
    - Each CSV file represents the expected results from the database after the ConceptQL's SQL query is run
- benchmark_results
    - Stores a set of CSV files in a structure that mirrors the statements directory
    - Each CSV file stores a queries execution time after averaging 10 iterations along with the standard deviation
- reports
    - Stores a set of CSV files that record sets of benchmark times
    - See reports section for more details
- tmp
    - Stores artifacts built as part of testing process
    - Everything in this directory can be safely removed and will be rebuilt as needed
    - If something funky is going on, wipe out this directory and try again
- db.rb
    - Thor-based Ruby file
    - See DB.RB section
- schemas
    - Stores Ruby Sequel-style schema information about CDMv4 to build validation/benchmark tables
- unrunnable_statements
    - Statements that I like, but aren't yet fully supported by ConceptQL or our testing data
- Gemfile\*
    - Used by Ruby's bundler gem to bootstrap gems needed for testing
- Rakefile
    - Used by Ruby's rake gem to help drive the test suite
    - See Rake section for more details
- .env
    - Stores important environment variables that determine things like:
        - The name of the database to use
        - The connection information


## Files of interest
- \*.pg
    - .pg files contain the actual dbtap tests that are run against the test database via the dbtap command
    - They live somewhere in the tmp directory


### Validation Tests
Validation tests run against a sample of 250 patients and their data.  For every validation statement we:
- Convert the ConceptQL statement into an SQL query
- Put the query into a "set_eq" dbtap test
- Check to see if the test results are in the database and if not
    - Create a schema to store the expected results for the test
    - Check to see if the results CSV file is present and if not
        - Run the query to gather the results and put them into the CSV file
            - That's right, we use the query generate the results we use to then test the query
            - This is madness, but it allowed us to bootstrap the validation testing process quickly
            - Others are working on generating an independent set of results that we'll ultimately use
    - Load the CSV contents into the database
- Put the dbtap test into a \*.pg file along with other related validation tests

Once the \*.pg files are generated, we use the dbtap command to run the test suite against the database

For the commands to execute this process, see the Rake section


### Benchmark Tests
Benchmark tests run against a sample of ~113,000 patients and their data.  For every benchmark statement we:
- Convert the ConceptQL statement into an SQL query
- Check to see if the test results are in the database and if not
    - Create a schema to store the expected results for the test
    - Check to see if the results CSV file is present and if not
        - Run the query 10 times to gather an average execution time and standard deviation on that time and dump them into a CSV file
            - Benchmark tests are dependent upon the hardware/PostgreSQL configuration of the server they are run on
            - This makes benchmark test results very ephemeral
            - The primary goal of benchmark tests are to ensure that changes to the database/ConceptQL SQL-generating engine don't introduce poor performing queries
- Put the query and expected execution time from the CSV file into a "performs_within" dbtap test
- Put the dbtap test into a \*.pg file along with other related validation tests

Once the \*.pg files are generated, we use the dbtap command to run the test suite against the database

For the commands to execute this process, see the Rake section


## Rake
Rake (Ruby's "make" program) drives the creation and execution of the dbtap tests that we run.  Run: ``bundle exec rake -T`` to see the list of possible commands you can execute.

The default behavior of rake (e.g. ``bundle exec rake`` with no arguments) is to run the validation and benchmark tests.

Like make, Rake has a series of dependencies that it checks to make sure all necessary files are in place for a given target.  The Rakefile defines the targets and their dependencies.

Here is a summary of the most relevant commands:
- rake validate
    - Runs validation tests
- rake benchmark
    - Runs benchmark tests
- rake benchmark:report
    - Consolidates all benchmark_results/\*\*/\*.csv files into a single, time-stamped file in the reports directory
    - Use this to snapshot your benchmarks so you can compare the results after you make some changes
- rake {validate,benchmark}:load_data
    - Loads the test data into the validation/benchmark database as needed


# DB.RB
db.rb is an in-progress utility to make it easier to interact with ConceptQL and it's resulting SQL.  It lets you see what SQL is generated for a ConceptQL statement, runs explain or explain analyze on that statement, and other things.

The db.rb file is a Thor-based script.  Ruby's thor gem allows for easy creation of a command-line utility.

Run this utility via ``bundle exec ruby db.rb [args]``

Running it with no arguments produces a short help file.

The most interesting feature of db.rb is the "try_index" command.  Give this command a ConceptQL statement file, a table name, and a list of columns in that table and the script will:
- Run explain on the SQL generated by the ConceptQL statement
- Add an index on the table's columns
- Run analyze on the table to update the statistics
- Run explain on the SQL generated by the ConceptQL statement again
- Compare the two explain statements against each other to show how the query planner behaves with the new index
- After exiting the diff window, you may keep the new index by typing "keep"
    - Otherwise, the index is removed


### Todo
- Lock-in the validation results
- Hash benchmark results to make sure the query fetches what we expect
    - Is this something I do once, like the first time, or for every iteration in a benchmark test?

## Thanks
- [Outcomes Insights, Inc.](http://outins.com)
    - Many thanks for allowing me to release a portion of my work as Open Source Software!

