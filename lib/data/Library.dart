class animeState {
  States state;
  List<dynamic> data;
  animeState(this.state, this.data);
}

class animeLibrary {
  List<animeState> lib = [];

  void addAnime(animeState anime) {
    lib.add(anime);
    lib.sort((a, b) => States.values.indexOf(a.state).compareTo(States.values.indexOf(b.state)));
  }
}

enum States { WATCHING, COMPLETED, PAUSED, DROPPED, PLANNING }
