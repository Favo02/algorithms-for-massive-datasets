#import "template.typ": *

#show: academic-notes.with(
  title: "Algorithms for Massive Datasets",
  subtitle: "University of Milan - Master's Degree in Computer Science",
  authors: (
    ("Luca Favini", "Favo02"),
    ("Giacomo Comitani", "comitanigiacomo"),
  ),
  repo-url: "https://github.com/Favo02/algorithms-for-massive-datasets",
  license: "CC-BY-4.0",
  license-url: "https://creativecommons.org/licenses/by/4.0/",
  last-modified-label: "Last modified",
  introduction: [
    #show link: underline
    = Algorithms for Massive Datasets

    Notes from the #link("https://malchiodi.di.unimi.it/teaching/AMD/2025-26/")[_Algorithms for Massive Datasets_] course (a.y. 2025/26),
    taught by Prof. _Dario Malchiodi_, Master's Degree in Computer Science,
    University Of Milan.

    Created by #(("Luca Favini", "Favo02"), ("Giacomo Comitani", "comitanigiacomo")).map(author => [#link("https://github.com/" + author.at(1))[#text(author.at(0))]]).join([, ]),
    with contributions from #link("https://github.com/Favo02/algorithms-for-massive-datasets/graphs/contributors")[other contributors].

    These notes are open source: #link("https://github.com/Favo02/algorithms-for-massive-datasets")[github.com/Favo02/algorithms-for-massive-datasets]
    licensed under #link("https://creativecommons.org/licenses/by/4.0/")[CC-BY-4.0].
    Contributions and corrections are welcome via Issues or Pull Requests.

    Last modified: #datetime.today().display("[day]/[month]/[year]").
  ],
)

#part("Theory")
#include "chapters/1-hdfs-mapreduce.typ"
#include "chapters/2-link-analysis.typ"

#include "chapters/4-frequent-itemsets.typ"

#show: appendix
#part("Implementation")

#include "chapters/a-spark.typ"
