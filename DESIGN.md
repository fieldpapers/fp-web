# Design (Philosophy)

Field Papers is built around a single [social
object](http://gapingvoid.com/so/), the _Atlas_.

Atlases consist of individual (typically printed) pages, including an index
page which serves as a table of contents. Atlases may also be associated with
_Snapshot_s, which are images of a particular page after it has interacted with
the real world.

CRUD Rails apps are typically comprised of (often nested) resources that map to
conceptual objects such as atlases, prints, snapshots, and users. Each object
is modeled by a Ruby object (`app/models`) and controlled both as a collection
and as individual entities (`app/controllers`) and viewed by users or other
applications (`app/views`).

Actions that can be taken on a model or collection thereof are grouped into
a single logical controller and assigned verbs according to use.

Thus, an atlas can be _show_n, _update_d, _print_ed, etc. Individual pages can
be _show_n.  Snapshots can be _upload_ed (_create_d, really) or otherwise
manipulated.

Corralling actions into controllers that manipulate individual classes of model
allows us to reduce the number of controllers necessary and to assist in the
process of navigating an unfamiliar codebase.

More complex workflows may not map as cleanly, hence the creation of such
things as the `ComposeController` (`CompositionController`, to fit into the
kingdom of nouns?) which aggregate stepwise functionality such as the
multi-step process involved in composing an atlas.
