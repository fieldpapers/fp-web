
## Views

We need to work on the views and the controller for the "compose"
routes.  There's no "compose" model, since "compose" is a kind of fake
resources that's just used for managing the atlas creation process.

The views are all in `app/views/compose`.  The views for the
individual steps are:

1. `search.html.erb`: location search;
2. `select.html.erb`: page composer;
3. `describe.html.erb`: notes;
4. `layout.html.erb`: flags.

There's also a partial view called `_composing_nav.html.erb` in the
same place that has breadcrumbs for stepping back and forth between
the individual steps.

(For all of these, `.html.erb` just means HTML with embedded Ruby
code.)


## Controller

 * The controller is in `app/controllers/compose_controller.rb`.  All
   line numbers below refer to this file.
 * The wizard functionality is set up by including the
   `Wicked::Wizard` class at the top of the controller definition
   (L7).  In the typical annoyingly implicit way that Rails does
   things, this defines a bunch of "magic" stuff to do with rendering
   the different wizard pages.  The documentation for this thing is
   here: http://www.rubydoc.info/gems/wicked/1.2.1
 * Because the atlas definition has to persist across multiple pages
   (search, select, describe, layout), the atlas definition is stored
   in the session (L22, L138, L149, etc.).  We won't need to do that,
   since we'll be constructing the data describing the atlas in one go
   in the front end.
 * The wizard works by doing stuff in the `show` and `update` methods
   of the controller.  The `show` method is called when you GET a
   resource and `update` is called when you do a PUT on a resource.
   In the `select.html.erb` view you can see that the form there
   overrides the normal POST method to use PUT to make sure the
   `update` method gets triggered correctly (same for `describe` and
   `layout`).  This is the mechanism the wizard uses to capture
   changes to data that's supposed to persist across "steps".
   Basically, we should be able to junk *all* of this and have a
   single view with all the UI stuff in it you've been doing, with a
   single "Submit" button that does a POST to the compose controller.
   It should be much simpler than the existing setup.
 * There is some stuff to do with "canned" atlases that we might need
   to work around (L22, L144).  I'm not 100% sure how this works, but
   I think you do a POST to the compose path with various payloads you
   can set up part of the atlas definition before you get into the UI.
   I think we might be able to recycle some of the validation code in
   the GeoJSON payload handling bit of this (L44-L120) for our
   purposes.


## Tasks

Following the advice I've seen about pair programming, I'm trying to
break things down into little tasks so that we can experience a
satisfying series of "tiny triumphs"...

1. Reorganise the views so we have a single
   `app/compose/show.html.erb` view that looks like the "big map"
   experiments you've been doing.

2. Remove all the wizard stuff from the controller and fix up the
   `show` method so that pressing the "Make an atlas" link on the
   front page brings up your "big map" view (without linking that back
   to the controller yet).

3. Fix up the `show` method to handle query parameters so that we can
   do all the necessary redirects (things like L142).  Then we can
   deal with all the places where there are redirects to
   `wizard_path(:something)` and similar.

4. Add code to your UI to send data back to the controller when you
   press a "Submit" button.  (This might require some messing around
   with Ruby form elements, but we'll deal with it.)

5. Repurpose the existing `create` method in the controller to allow
   it to process data sent from the UI on a POST.  Ideally, do that
   without breaking the "canned maps" functionality.

6. Clean up dependencies, maybe write some tests (although `fp-web`
   doesn't really have any!), make a PR, sit back and feel smug...

I'm sure there will be things I've forgotten, but this seems like it
will be a good start, and probably enough for more than one pair
programming session, depending on how incompetent we collectively are
at Rails programming.  (I've done some, but not much, and I don't like
Rails very much, but it's what's there for Field Papers.  We'll work
on the "See one, do one, teach one" basis that doctors do...)


## Next steps

 * Figure out asset pipeline: `big_map.css` not compiling; `<script>`
   at the bottom of `new.html.erb` should be moved into a separate JS
   file or cleaned up. [**Ian**: `big_map.css` **DONE**]

 * Get `mapbox-rails` gem working. [**Ian**: **DONE**]

 * Improve atlas field names: `:text` to `:notes`, `:layout` to
   `:include_notes` or something like that. [**Ian**]

 * Figure out proper hidden fields. [**Ian**: **DONE**]

 * Wire up changes to map location, zoom, rows and columns to hidden
   form fields. [**Lindsey**: **DONE**]

 * Tidy up menu layout.  [**Lindsey**: **DONE**]

 * Deal with backend data processing.  [**Ian**: **PARTIALLY DONE**]


## Next steps, Mark 2

 * Tidy up accordions.  [**Lindsey**: **DONE**]

 * Make "Field Papers" logo on map bigger (same size as on other
   pages).  [**Lindsey**]

 * Scroll wheel map zooming.  [**Lindsey**: **DONE**]

 * Buttons: "Make atlas" and "Cancel".  [**Lindsey**]

 * Make sure initial view in front end is initialised from initial
   values passed by back end.  [**Lindsey** and **Ian**]

 * Get atlas rendering working correctly.  (Do side-by-side comparison
   of what's getting to task manager from back-end in "old"
   vs. "new".)  [**Ian**: **DONE**]

 * Get canned atlases working correctly.  (This goes with making sure
   the initial view in the front end matches what's being sent from
   the back end, but there might be some other bits to it.)  [**Ian**]

 * Mocks of UI layout changes.  [**Lindsey** and **Chandra**]

 * Grid interaction playground.  [**Lindsey** and **Ian**]

 * Interaction playground to AWS.  [**Ian** and **Lindsey**]

 * Set up survey for UI layout/interaction model choices.   [**Lindsey**]

 * Survey translations.  [**Cadasta and friends**]
