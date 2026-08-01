# Blog Forum App — Progress

## Preparation
- [x] Setup a flutter project.
- [x] Repo + git connection setup.
- [x] Supabase setup, schema + RLS done, storage bucket next.
- [x] Supabase storage bucket setup (post_images, public + 2 policies).
- [x] File structure

## Steps (Making the actual Project)
- [x] 1. Flutter Project + Supabase connected
- [x] 2. Auth (register/login/logout)
- [x] 3. Post listing (public, paginated)
- [x] 4. Post create/edit + images
- [x] 5. Post detail + delete
- [x] 6. Comments + images
- [x] 7. Profile (avatar + name)
- [x] 8. Deploy to vercel :D
- [ ] 9. Submit to HR

## Polishing (gotta make the website beautiful right?)
- [x] 1. Show author name + avatar on posts and comments
- [x] 2. Relative timestamps ("e.g. 2w/d/h/m/now ago")
- [x] 3. Empty states ("No comments yet", etc.)
- [x] 4. Comment count shown on post list cards
- [x] 5. Visual/style pass using design reference (spacing, colors, typography)
- [x] 6. Tap-to-enlarge image viewer
- [x] 7. Dark/Light Mode
- [ ] 8. Mobile browser compatible

## Few bug fixes
- [x] Postly Logo does not take you to the main page.
- [x] Light/Dark mode switch is going back to the very top of the page.
- [x] Hyperlink not work, need actual popup to input the link
- [x] importantly, the login/register popup. Not popping up on post_list
- [x] Searching non existing posts shows a skeleton loading infinitely
- [x] Login should popin when the user tries to press the like button when not logged in
- [x] Login/register eye buttons. Remove the X buttons
- [x] Make tabbing on inputs be smooth, as of now it keeps tabbing on the X buttons (but these X buttons will be replaced)
- [x] Clicking on an autocompleted search in the searchbar should instantly search for it. Because as of now it justs prints the word on the searchbar i had to press enter
- [x] Need to put a name input inside register.
- [x] The profile edit, the pencil icon is pressable, but i cant actually input a new name.
- [x] Profile photo not showing when logging in. 

## Key Decisions
- Images stored as separate rows (post_images, comment_images) not array columns, makes us so that they can delete individual images without rewriting a whole array.
- RLS policies at DB level (auth.uid() = user_id), not relying on frontend so that we dont end up letting users access others.
- Image files live in Supabase Storage; DB only stores the resulting URL (post_images.url & comment_images.url).
- Storage bucket is Public (handles reads), 2 policies added for insert (authenticated only) and delete (owner only, checked via folder name = user_id).
- Should have a tap to enlarge image view for comments and posts.
- An actual button for the dark/light mode.
- Removed alot of stuffs, redesigned alot of stuffs, fixed alot of stuffs, added more stuffs.

## Environment
- Supabase project name: blog_forum_app
- Flutter project name: blog_forum_app
- GitHub repo: https://github.com/Gel0oo/blog-forum-app
- Flutter SDK version: 3.44.0