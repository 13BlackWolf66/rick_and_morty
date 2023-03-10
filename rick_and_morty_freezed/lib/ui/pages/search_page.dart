import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rick_and_morty_freezed/bloc/character_bloc.dart';
import 'package:rick_and_morty_freezed/data/models/character.dart';
import 'package:rick_and_morty_freezed/ui/pages/widgets/custom_list_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Character currentCharacter;
  List<Results> currentResults = List<Results>.empty(growable: true);
  int currentPage = 1;
  String currntSearchString = '';
  final refreshController = RefreshController();
  bool isPagination = false;
  final storage = HydratedBloc.storage;
  @override
  void initState() {
    if (storage.runtimeType.toString().isEmpty) {
      if (currentResults.isEmpty) {
        context
            .read<CharacterBloc>()
            .add(const CharacterEvent.fetch(name: '', page: 1));
      }else{}
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CharacterBloc>().state;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 15, bottom: 15, left: 16, right: 16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromRGBO(86, 86, 86, 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              hintText: 'Search Name',
              hintStyle: const TextStyle(color: Colors.white),
            ),
            onChanged: (value) {
              currentPage = 1;
              currentResults = [];
              currntSearchString = value;
              context
                  .read<CharacterBloc>()
                  .add(CharacterEvent.fetch(name: value, page: currentPage));
            },
          ),
        ),
        Expanded(
          child: state.map(
            loading: (_) {
              if (!isPagination) {
                return Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Loading...'),
                    ],
                  ),
                );
              } else {
                return _customListView(currentResults);
              }
            },
            loaded: (characterLoaded) {
              currentCharacter = characterLoaded.characterLoaded;
              if (isPagination) {
                currentResults.addAll(currentCharacter.results);

                refreshController.loadComplete();
                isPagination = false;
              } else {
                currentResults.clear();
                currentResults.addAll(currentCharacter.results);
              }
              return currentResults.isNotEmpty
                  ? _customListView(currentResults)
                  : const Placeholder();
            },
            error: (_) => const Text('Nothing found...'),
          ),
        ),
      ],
    );
  }

  Widget _customListView(List<Results> currentResults) {
    return SmartRefresher(
      controller: refreshController,
      enablePullUp: true,
      enablePullDown: false,
      onLoading: () {
        isPagination = true;
        currentPage++;
        if (currentPage <= currentCharacter.info.pages) {
          context.read<CharacterBloc>().add(CharacterEvent.fetch(
              name: currntSearchString, page: currentPage));
        } else {
          refreshController.loadNoData();
        }
      },
      child: ListView.separated(
        itemBuilder: (context, index) {
          return Padding(
              padding:
                  const EdgeInsets.only(right: 16, left: 16, top: 3, bottom: 3),
              child: CustomListTile(
                result: currentResults[index],
              ));
        },
        separatorBuilder: (_, index) => const SizedBox(height: 5),
        itemCount: currentResults.length,
        shrinkWrap: true,
      ),
    );
  }
}
