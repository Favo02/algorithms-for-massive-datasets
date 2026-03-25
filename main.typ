#import "template.typ": *

#show: academic-notes.with(
  // --- Required
  title: "Algorithms for Massive Datasets",
  subtitle: "University of Milan - Master's Degree in Computer Science",
  authors: (
    ("Luca Favini", "Favo02"),
    ("Giacomo Comitani", "comitanigiacomo"),
  ),
  lang: "en",

  // --- Optional, uncomment to change
  repo-url: "https://github.com/Favo02/algorithms-for-massive-datasets",
  course-url: "https://malchiodi.di.unimi.it/teaching/AMD/2025-26/",
  year: "2025/26",
  lecturer: "Dario Malchiodi",
  // date: datetime.today(),
  // license: "CC-BY-4.0",
  // license-url: "https://creativecommons.org/licenses/by/4.0/",
  // heading-numbering: "1.1.",
  // equation-numbering: none,
  // page-numbering: "1",

  // --- Optional with language-based defaults, uncomment to change
  // introduction: auto,
  // last-modified-label: auto,
  // outline-title: auto,
  // part-label: auto,
  // note-title: auto,
  // warning-title: auto,
  // informally-title: auto,
  // example-title: auto,
  // proof-title: auto,
  // theorem-title: auto,
  // theorem-label: auto,
  // equation-supplement: auto,
  // figure-supplement: auto,
)

#show: part.with("Theory")
#include "chapters/1-hdfs-mapreduce.typ"
#include "chapters/2-link-analysis.typ"
#include "chapters/3-similarity.typ"
#include "chapters/4-frequent-itemsets.typ"
#include "chapters/5-data-streams.typ"



#include "chapters/6-clustering.typ"




#include "chapters/7-regression.typ"





#include "chapters/8-recommendation.typ"

#show: part.with("Implementation", chapters-numbering: "A.1.", reset-chapters: true)

#include "chapters/a-spark.typ"
