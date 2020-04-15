//  Created by Sean Heber on 6/24/10.

#ifdef DEBUG
	#define DebugLog(...) NSLog(__VA_ARGS__)
#else
	#define DebugLog(...) do {} while (0)
#endif

#define ReleaseLog(...) NSLog(__VA_ARGS__)

#define DEBUG_AUTO_LAYOUT 0
#if DEBUG_AUTO_LAYOUT
#define AutoLayoutLog(...) NSLog(__VA_ARGS__)
#else
#define AutoLayoutLog(...) do {} while (0)
#endif
