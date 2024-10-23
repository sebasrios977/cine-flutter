import 'package:cinemapedia/domain/entities/actor.dart';
import 'package:cinemapedia/infrastructure/models/moviedb/credits_response.dart';

class ActorMapper {

  static Actor castToEntity (Cast cast) => Actor(
    id: cast.id, 
    name: cast.name, 
    profilepath: cast.profilePath != null
    ? 'https://image.tmdb.org/t/p/w500${cast.profilePath}'
    : 'https://static.thenounproject.com/png/3039079-200.png', 
    character: cast.character
  );
}