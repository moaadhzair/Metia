class animeState {
  States state;
  List<dynamic> data;
  animeState(this.state, this.data);
}

class animeLibrary {
  List<animeState> lib = [];

  void addAnime(animeState anime) {
    lib.add(anime);
  }
}

enum States { COMPLETED, WATCHING, PAUSED, DROPPED, PLANNING }
