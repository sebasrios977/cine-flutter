import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cinemapedia/config/helpers/human_formats.dart';
import 'package:cinemapedia/domain/entities/movie.dart';
import 'package:flutter/material.dart';


typedef SearchMoviesCallback = Future<List<Movie>> Function(String query);

class SearchMovieDelegate extends SearchDelegate<Movie?> {

  final SearchMoviesCallback searchMovies;
  List<Movie> initialMovies;
  StreamController<List<Movie>> debounceMovies = StreamController.broadcast();
  StreamController<bool> isLoadingStream = StreamController.broadcast();

  Timer? _debounceTimer;


  SearchMovieDelegate({
    required this.searchMovies, 
    required this.initialMovies
  });

  void clearStreams() {
    debounceMovies.close();
  }

  void _onQueryChanged(String query) {
    isLoadingStream.add(true);
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // if (query.isEmpty) {
      //   debounceMovies.add([]);
      //   return;
      // }

      final movies = await searchMovies(query);
      if (debounceMovies.isClosed) return;
      initialMovies = movies;
      debounceMovies.add(movies);
      isLoadingStream.add(false);
    });
  }

  Widget buildResultsAndSuggestions() {
    return StreamBuilder(
      initialData: initialMovies,
      stream: debounceMovies.stream,
      builder: ((context, snapshot) {
        final movies = snapshot.data ?? [];

        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return _MovieItem(
              movie: movie,
              onMovieSelected: (context, movie) {
                clearStreams();
                close(context, movie);
              },
            );
          },
        );
      })
    );
  }

  @override
  String get searchFieldLabel => 'Buscar pelicula';
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      StreamBuilder(
        initialData: false,
        stream: isLoadingStream.stream, 
        builder: (context, snapshot) {
          if (snapshot.data ?? false) {
            return SpinPerfect(
              duration: const Duration(seconds: 1),
              infinite: true,
              child: IconButton(
                onPressed: () => query = '',
                icon: const Icon(Icons.refresh_rounded),
              ),
            );
          }

          return FadeIn(
            animate: query.isNotEmpty,
            child: IconButton(
              onPressed: () => query = '',
              icon: const Icon(Icons.clear),
            ),
          );
        }
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        clearStreams();
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back_ios_new),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
      return buildResultsAndSuggestions();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _onQueryChanged(query);
    return buildResultsAndSuggestions();
  }

}


class _MovieItem extends StatelessWidget {

  final Movie movie;
  final Function onMovieSelected;

  const _MovieItem({required this.movie, required this.onMovieSelected});

  @override
  Widget build(BuildContext context) {

    final textStyles = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        onMovieSelected(context, movie);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: size.width * 0.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  movie.posterPath, 
                  loadingBuilder: (context, child, loadingProgress) => FadeIn(child: child),
                ),
              ),
            ),
    
            const SizedBox(width: 10),
    
            SizedBox(
              width: size.width * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: textStyles.titleMedium),
    
                  (movie.overview.length > 100) 
                    ? Text('${movie.overview.substring(0, 100)}...', style: textStyles.bodySmall) 
                    : Text(movie.overview, style: textStyles.bodySmall),
    
                  Row(
                    children: [
                      const Icon(Icons.star_half_rounded, color: Colors.amber),
                      const SizedBox(width: 5),
                      Text(HumanFormats.number(movie.voteAverage, 1), style: textStyles.bodyMedium!.copyWith(color: Colors.amber.shade900),),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}