# Blog Forum App — Progress

## Preparation
- [x] Setup a flutter project.
- [x] Repo + git connection setup.
- [x] Supabase setup, schema + RLS done, storage bucket next.
- [x] Supabase storage bucket setup (post_images, public + 2 policies).

## Steps (Making the actual Project)
- [ ] 1. Flutter Project + Supabase connected
- [ ] 2. Auth (register/login/logout)
- [ ] 3. Post listing (public, paginated)
- [ ] 4. Post create/edit + images
- [ ] 5. Post detail + delete
- [ ] 6. Comments + images
- [ ] 7. Profile (avatar + name)
- [ ] 8. Deploy + submit

## Key Decisions
- Images stored as separate rows (post_images, comment_images) not array columns — makes us so that I can delete individual images without rewriting a whole array.
- RLS policies at DB level (auth.uid() = user_id) — not relying on frontend so that we don't end up letting users access others.
- Image files live in Supabase Storage; DB only stores the resulting URL (post_images.url & comment_images.url).
- Storage bucket is Public (handles reads); 2 policies added for insert (authenticated only) and delete (owner only, checked via folder name = user_id).

## Environment
- Supabase project name: blog_forum_app
- Flutter project name: blog_forum_app
- GitHub repo: https://github.com/Gel0oo/blog-forum-app
- Flutter SDK version: 3.44.0