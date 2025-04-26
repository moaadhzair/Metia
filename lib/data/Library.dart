class AnimeState {
  String state; // the state is the name of the list of entries which is received by anilist api
  List<dynamic> data;
  AnimeState(this.state, this.data);
}

class AnimeLibrary {
  List<AnimeState> lib = [];

  void addAnime(AnimeState anime) {
    lib.add(anime);
    }
}
