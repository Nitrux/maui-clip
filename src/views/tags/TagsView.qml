import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

import ".."

StackView
{
    id: control
    objectName: "TagsView"
    background: null

    property bool useInternalChrome: true
    property string currentTag: ""
    readonly property bool filteringTag: depth > 1
    property Flickable flickable: currentItem.flickable

    initialItem: TagsGrid
    {
        id: _tagsGrid
        useInternalChrome: control.useInternalChrome
    }

    Component
    {
        id: _filterViewComponent

        BrowserLayout
        {
            id: _tagBrowser
            useInternalChrome: control.useInternalChrome
            allowLassoSelection: false
            showTitle: false
            title: control.currentTag
            background: null
            list.recursive: false
            listView.cacheBuffer: Math.max(height * 2, Maui.Style.units.gridUnit * 24)
            listView.flickable.reuseItems: true
            holder.title: i18n("No Videos!")
            holder.body: i18n("There are no videos associated with this tag.")

            onItemClicked: function(item)
            {
                play(item)
            }

            Component.onCompleted: syncTagSource()
            onTitleChanged: syncTagSource()

            function syncTagSource()
            {
                const nextUrl = control.currentTag.length ? "tags:///" + control.currentTag : ""
                const currentUrls = list.urls

                if (currentUrls.length === (nextUrl ? 1 : 0)
                        && (!nextUrl || currentUrls[0] === nextUrl))
                    return

                list.urls = nextUrl ? [nextUrl] : []
            }
        }
    }

    function populateGrid(myTag)
    {
        currentTag = myTag

        if (control.depth > 1)
            control.pop()

        control.push(_filterViewComponent)
    }

    function search(text)
    {
        if (currentItem && currentItem.search)
            currentItem.search(text)
    }

    function clearSearch()
    {
        if (currentItem && currentItem.clearSearch)
            currentItem.clearSearch()
    }

    function goBack()
    {
        if (filteringTag)
            control.pop()
    }

    function currentSortIndex()
    {
        return _tagsGrid.currentSortIndex()
    }

    function applySort(index)
    {
        _tagsGrid.applySort(index)
    }
}
