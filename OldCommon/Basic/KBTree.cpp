//////////////////////////////////////////////////////////////////////////////
//
//   (c) Copyright 1999,2000 Trustees of Dartmouth College, All rights reserved.
//        Interactive Media Lab, Dartmouth Medical School
//
//			$Author$
//          $Date$
//          $Revision$
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
//
// KBTree.cpp : 
//

#include "KHeader.h"
#include "KBTree.h"

//
//	KBNode
//
KBNode::KBNode()
{
	InitMembers();
}

KBNode::KBNode(const char *inKey)
{
	InitMembers();
	m_Key = inKey;
}

KBNode::KBNode(KString &inKey)
{
	InitMembers();
	m_Key = inKey;
}

void KBNode::InitMembers(void)
{
	m_Key.Empty();
	m_Left = NULL;
	m_Right = NULL;
}

KBNode::~KBNode()
{
	
}

//
//	Add - Add a node to this one. Figure out where it goes and
//		put it there.
//
bool KBNode::Add(KBNode *inNode)
{
    int32 result = m_Key.Compare(inNode->Key(), false);

	// cbo - make sure the fields of the node are NULL!
	inNode->m_Left = NULL;
	inNode->m_Right = NULL;
	
    if (result < 0)
    {
        if (m_Right == NULL) 
        	m_Right = inNode;
        else 
        	m_Right->Add(inNode); 
	}
    else if (result > 0)
    {
        if (m_Left == NULL) 
        	m_Left = inNode;
        else 
        	m_Left->Add(inNode);
	}
    else
		return (false);

	return (true);
}

//
//	FindMin - Find the next smallest node compared to 
//		this one.
//
KBNode *KBNode::FindMin(void)
{
	KBNode	*cursor = this;
	KBNode	*retNode;

	if (cursor->m_Left == NULL) 
    	return (cursor);

	while (cursor->m_Left->m_Left != NULL)
		cursor = cursor->m_Left;

    retNode = cursor->m_Left;

    cursor->m_Left = cursor->m_Left->m_Right;

    return (retNode);
}

//
//	Remove - Remove this node and return the sub-tree that is 
//		formed.
//
KBNode *KBNode::Remove(void)
{
    KBNode	*retNode;
	KBNode	*tmpNode;

    if (this == NULL) 
    	return this;

    if (m_Right == NULL) 
    {
        retNode = m_Left;
        delete this;
        return (retNode);
    }

    tmpNode = m_Right->m_Left;
    retNode = m_Right->FindMin();

    if (tmpNode != NULL)
        retNode->m_Right = m_Right;
    retNode->m_Left = m_Left;

    delete this;
    
    return (retNode);
}

//
//	FindAndRemove - 
//
KBNode *KBNode::FindAndRemove(const char *inKey)
{
	KBNode	*tmpNode = this;
    int32 	result;

    result = m_Key.Compare(inKey, false);

    if (result == 0) 
		return (Remove());		// this is the one we are going to remove

    for ( ; tmpNode != NULL; result = tmpNode->m_Key.Compare(inKey, false))   
    {
        if (result < 0)  
        {
            if (tmpNode->m_Right != NULL) 
                return (NULL);
            else  
            {
                if (tmpNode->m_Right->m_Key.Compare(inKey, false) == 0) 
                {
                    tmpNode->m_Right = tmpNode->m_Right->Remove();
                    return (this);
				}
                else 
                    tmpNode = tmpNode->m_Right;
            }
        }
        else if (result > 0)  
        {
            if (tmpNode->m_Left != NULL) 
                return (NULL);
            else  
            {
                if (tmpNode->m_Left->m_Key.Compare(inKey, false) == 0) 
                {
                    tmpNode->m_Left = tmpNode->m_Left->Remove();
                    return (this);
                }
                else 
                    tmpNode = tmpNode->m_Left;
            }
        }
    }

    return (this);
}   

//
//	Find
//
KBNode *KBNode::Find(const char *inKey)
{
	if (inKey == NULL)
		return (NULL);

    int32 result = m_Key.Compare(inKey, false);

    if (result < 0)
    {
        if (m_Right == NULL) 
        	return (NULL);
        else 
        	return (m_Right->Find(inKey));
    }
    else if (result > 0)
    {
        if (m_Left == NULL) 
        	return (NULL);
        else 
        	return (m_Left->Find(inKey));
    }
    else
        return (this);
}

//
//	RemoveAll - Destroy this sub-tree.
//
void KBNode::RemoveAll(KBNode *inRoot)
{
    if (this == NULL) 
    	return;

    if (m_Left != NULL) 
    { 
    	m_Left->RemoveAll(inRoot);
    	m_Left = NULL;
    }

    if (m_Right != NULL) 
    {
    	m_Right->RemoveAll(inRoot);
    	m_Right = NULL;
    }

    if (this != inRoot)
    	delete this;
}

//
//	KBTree methods
//

KBTree::KBTree()
{
    m_Root = NULL;
}

KBTree::~KBTree()
{
    if (m_Root != NULL) 
    	delete m_Root;
}

//
//	Root - Return the root node.
//
KBNode *KBTree::GetRoot()
{
	return (m_Root);
}

//
//	Add - Add a node to the tree.
//
void KBTree::Add(KBNode *inNode)
{
    if (m_Root == NULL)
        m_Root = inNode;
    else
        m_Root->Add(inNode);
}

//
//	Find - Find a node.
//
KBNode *KBTree::Find(const char *inKey)
{
    KBNode   *retNode = NULL;

    if (m_Root != NULL)
    	retNode = m_Root->Find(inKey);

    return (retNode);
}

//
//	Remove - Remove the node with inKey from
//		the tree.
//
void KBTree::Remove(const char *inKey)
{
	if (m_Root != NULL)
	{
		if (m_Root->Find(inKey))
			m_Root = m_Root->FindAndRemove(inKey);
	}
}

//
// RemoveAll - Remove everything in this tree.
//
void KBTree::RemoveAll(void)
{
    if (m_Root != NULL)
    { 
    	m_Root->RemoveAll(m_Root);
    	delete m_Root;
    	m_Root = NULL;
    }
}

/*
 $Log$
 Revision 1.1  2000/05/11 12:59:44  chuck
 v 2.01 b1

*/
