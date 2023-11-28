#include <SDL/SDL.h> 
#include <SDL/SDL_image.h>
#include <stdlib.h> 

int main(int argc, char *argv[])   { 
   Uint32 flags = SDL_SWSURFACE|SDL_FULLSCREEN; 

   printf("\n");
   if (SDL_Init(SDL_INIT_VIDEO) < 0)   { 
      printf("SDL_Init failed\n");
      return -1; 
   } 

	SDL_Surface *screen; 
	SDL_Surface *image; 

	screen = SDL_SetVideoMode(480, 272, 32, flags); 
	image  = IMG_Load("jive/splash.png");
	if (NULL == image) {
		printf("IMG_Load failed\n");
	}

	/* Puting image on the screen */ 
	if (0 != SDL_BlitSurface(image, NULL, screen, NULL)) {
		printf("SDL_BlitSurface failed\n");
	}
 	SDL_Flip(screen);
 	//SDL_Delay(4000);
	// stackoverflow 34424816 to the rescue
#ifndef false
#define false 0
#endif
#ifndef true
#define true 1
#endif

	SDL_Event e;
	int quit = false;
	while (!quit){
    while (SDL_PollEvent(&e)){
        if (e.type == SDL_QUIT){
            quit = true;
        }
        if (e.type == SDL_KEYDOWN){
            quit = true;
        }
        if (e.type == SDL_MOUSEBUTTONDOWN){
            quit = true;
        }
    }
}

	return 0;
}
