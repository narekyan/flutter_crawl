
import 'dart:async';

import 'package:http/http.dart' as http;


class CrawlerResponse {
  String url;
  int count;
  bool end = false;

  CrawlerResponse(url, count, end) {
    this.url = url;
    this.count = count;
    this.end = end;
  }
}

class Crawler {
  Uri webPage;
  String expression;
  int countOfSubPages = 0;
  int totalCount;
  Set<String> visitedPages = Set();
  Set<Uri> _pagesToVisit = Set();
  StreamController<CrawlerResponse> response = StreamController();

  void start() {
    _pagesToVisit.clear();
    visitedPages.clear();
    totalCount = 0;
    _pagesToVisit.add(webPage);

    crawl();
  }

  void crawl() {
    if (visitedPages.length > countOfSubPages) {
      response.add(CrawlerResponse("", 0, true));
      return;
    }
    Uri pageToVisit = _pagesToVisit.first;
    _pagesToVisit.remove(pageToVisit);
    if (pageToVisit == null) {
      response.add(CrawlerResponse("", 0, true));
      return;
    }

    if (visitedPages.contains(pageToVisit.toString())) {
      crawl();
    } else {
      visit(pageToVisit);
    }
  }

  void visit(Uri url) {
    visitedPages.add(url.toString());

    http.read(url.toString()).then((contents) {
      if (contents.isEmpty) {
        crawl();
        return;
      }
      parse(contents, url);
      crawl();
    });
  }

  void parse(String content, Uri url) {
    RegExp regex = RegExp(expression, caseSensitive: false);
    Iterable<RegExpMatch> matches = regex.allMatches(content);
    totalCount += matches.length;

    response.add(CrawlerResponse(url.toString(),matches.length, false));

    gatherSubPages(content).forEach((element) { _pagesToVisit.add(element); });
  }

  List<Uri> gatherSubPages(String content)  {
    String pattern = "href=\"(http://.*?|https://.*?)\"";
    RegExp regex = RegExp(pattern, caseSensitive: false);
    Iterable<RegExpMatch> matches = regex.allMatches(content);


    List<Uri> result = List<Uri>();
    for (var e in matches) {
      String url1 = content.substring(e.start, e.end);
      url1 = url1.substring(0, url1.length-1);
      url1 = url1.substring("href=\"".length, url1.length);
      result.add(Uri.parse(url1));
    }
    return result;
  }
}