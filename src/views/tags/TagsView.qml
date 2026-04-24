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
            list.urls: ["tags:///" + currentTag]
            list.recursive: false
            holder.title: i18n("No Videos!")
            holder.body: i18n("There are no videos associated with this tag.")

            onItemClicked: play(item)
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
