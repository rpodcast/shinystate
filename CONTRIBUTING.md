# Information and Guidelines for Contributing to shinystate

There are many ways to contribute to the ongoing development of the
**shinystate** package. Some contributions can be rather easy to do
(e.g., fixing typos, improving documentation, filing issues for feature
requests or problems, etc.) whereas other contributions can require more
time and patience (like answering questions and submitting pull requests
with code changes). Just know that that help provided in any capacity is
very much appreciated! :)

## Filing Issues

If you believe you found a bug, create a minimal
[reprex](https://forum.posit.co/t/shiny-debugging-and-reprex-guide/10001#creating-shiny-reprexes-2)
for your posting to the [**shinystate** issue
tracker](https://github.com/rpodcast/shinystate/issues). Try not to
include anything unnecessary, just the minimal amount of code that
constitutes the reproducible bug. We will try to verify the bug by
running the code in the reprex provided. The quality of the reprex will
reduce the amount of back-and-forth communication in trying to
understand how to execute the code on our systems.

We realize that creating a reprex involving a Shiny application can be
challenging. Hence it is highly recommended to consult the
aforementioned Shiny debugging and reprex guide for valuable
information. In addition, we recommend that your reprex utilizes a local
[`{pins}`](https://pins.rstudio.com/) board (such as `board_local()` or
`board_folder()` if you are not utilizing the default settings), and not
a board hosted on a cloud service such as `board_databricks()`,
`board_ms365()`. `board_azure()`, `board_gcs()`, `board_gdrive()`.

### Making Pull Requests

Should you consider making a pull request (PR), please file an issue
first and explain the problem in some detail. If the PR is an
enhancement, detail how the change would make things better for package
users. Bugfix PRs also require some explanation about the bug and how
the proposed fix will remove that bug. A great way to illustrate the bug
is to include a
[reprex](https://forum.posit.co/t/shiny-debugging-and-reprex-guide/10001#creating-shiny-reprexes-2).
While all this upfront work prior to preparing a PR can be
time-consuming it opens a line of communication with the package authors
and the community, perhaps leading to better enhancement or more
effective fixes!

Once there is consensus that a PR based on the issue would be helpful,
adhering to the following process will make things proceed more quickly:

- Create a
  [fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo)
  of the shinystate repository.
- Create a separate Git branch for each PR.
- The **shinystate** package follows the tidyverse [style
  guide](http://style.tidyverse.org) so please adopt those style
  guidelines in your submitted code as best as possible.
- The internal documentation uses
  [roxygen2](https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html);
  if your contribution requires new or revised documentation ensure that
  the roxygen comments are added/modified (do not modify any `.Rd` files
  in the `man` folder).
- We use [testthat](https://cran.r-project.org/web/packages/testthat/)
  for code coverage; those contributions with test cases included are
  helpful easier to accept.
