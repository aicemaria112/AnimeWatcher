import 'package:flutter/material.dart';
import '../models/manga.dart';
import 'dart:ui' as ui;

class MangaCard extends StatefulWidget {
  final Manga manga;
  final VoidCallback onTap;

  const MangaCard({super.key, required this.manga, required this.onTap});

  @override
  State<MangaCard> createState() => _MangaCardState();

}

class _MangaCardState extends State<MangaCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _elevationAnimation = Tween<double>(begin: 4, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    // Start the entrance animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Get color based on manga type/demography
  Color getGenreColor(String type) {
    switch (type.toLowerCase()) {
      case 'manga':
        return Colors.orange;
      case 'manhwa':
        return Colors.purple;
      case 'manhua':
        return Colors.green;
      case 'novel':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  // Get color based on demography
  Color getDemographyColor(String demography) {
    switch (demography.toLowerCase()) {
      case 'shounen':
      case 'shonen':
        return Colors.orange;
      case 'seinen':
        return Colors.purple;
      case 'shoujo':
      case 'shojo':
        return Colors.pink;
      case 'josei':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isHovering 
                  ? getGenreColor(widget.manga.type).withOpacity(0.3) 
                  : Colors.black.withOpacity(0.2),
                blurRadius: _isHovering ? 12 : 8,
                spreadRadius: _isHovering ? 2 : 0,
              ),
            ],
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              elevation: _isHovering ? _elevationAnimation.value : 4,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: _isHovering 
                  ? BorderSide(color: getGenreColor(widget.manga.type).withOpacity(0.5), width: 1.5) 
                  : BorderSide.none,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: getGenreColor(widget.manga.type).withOpacity(0.3),
                  highlightColor: getGenreColor(widget.manga.type).withOpacity(0.1),
                  onTap: widget.onTap,
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3/4,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return ui.Gradient.radial(
                            Offset(rect.width / 2, rect.height / 2),
                            rect.width * 1.5,
                            [
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            [0.0, 1.0],
                          );
                        },
                        blendMode: BlendMode.srcATop,
                        child: Transform.scale(
                          scale: 1.0 + (_isHovering ? 0.05 : 0.0),
                          child: Opacity(
                            opacity: value,
                            child: Image.network(
                              widget.manga.mangaImagen,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.error)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: _isHovering
                        ? RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              getGenreColor(widget.manga.type).withOpacity(0.0),
                              Colors.black.withOpacity(0.3),
                            ],
                            stops: const [0.3, 0.6],
                          )
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.transparent],
                          ),
                    ),
                    child: _isHovering
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                getGenreColor(widget.manga.type).withOpacity(0.2),
                                Colors.transparent,
                                getDemographyColor(widget.manga.demography).withOpacity(0.2),
                              ],
                            ),
                          ),
                        )
                      : null,
                  ),
                ),
                if (widget.manga.score != '0.00')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isHovering
                                ? getGenreColor(widget.manga.type).withOpacity(0.8)
                                : Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isHovering
                                ? [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  builder: (context, value, child) {
                                    return Transform.rotate(
                                      angle: value * 2 * 3.14159,
                                      child: const Icon(Icons.star, size: 16, color: Colors.amber),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.manga.score,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isHovering ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.manga.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8), // Aumentado de 4 a 8 para dar más espacio
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 50, // Aumentado de 40 a 50 para dar más espacio a los chips
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            // Type tag with enhanced visuals
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getGenreColor(widget.manga.type).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: getGenreColor(widget.manga.type).withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: getGenreColor(widget.manga.type).withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.manga.type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: getGenreColor(widget.manga.type),
                                ),
                              ),
                            ),
                            // Demography tag
                            if (widget.manga.demography.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getDemographyColor(widget.manga.demography).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: getDemographyColor(widget.manga.demography).withOpacity(0.5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: getDemographyColor(widget.manga.demography).withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.manga.demography,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: getDemographyColor(widget.manga.demography),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
          ),
        ),
      ),
  );
  }
}