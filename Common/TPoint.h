//////////////////////////////////////////////////////////////////////////////
//
//   (c) Copyright 1999, Trustees of Dartmouth College, All rights reserved.
//        Interactive Media Lab, Dartmouth Medical School
//
//			$Author$
//          $Date$
//          $Revision$
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
//
// TPoint.h : 
//

#if !defined (_TPoint_h_)
#define _TPoint_h_

#include "TCommon.h"
#include "TObject.h"

BEGIN_NAMESPACE_FIVEL

/*-----------------------------------------------------------------

CLASS
    TPoint

	A class to represent a point in 2D space.    

AUTHOR
    Chuck Officer<br>

------------------------------------------------------------------*/
class TPoint : public TObject
{ 
    public:
		//////////
		// Constructor.
		//
		// [in_optional] inX - set the X-coordinate (default 0)
		// [in_optional] inY - set the y-coordinate (default 0)
		//
		TPoint(int32 inX = 0, int32 inY = 0);

		//////////
		// Copy Constructor.
		//
		// [in] inPt - a TPoint to copy from
		//
		TPoint(TPoint &inPt);

		//////////
		// Set values for the point.
		//
		// [in] inX - set the X-coordinate
		// [in] inY - set the y-coordinate
		//
		void			Set(int32 inX, int32 inY);

		//////////
		// Set values for the point using another TPoint.
		//
		// [in] inPt - TPoint to copy values from
		//
		void			Set(const TPoint &inPt);

		//////////
		// Offset the point using another TPoint.
		//
		// [in] inPt - TPoint used to offset values for this point
		//
		void			Offset(TPoint &inPt);

		//////////
		// Set the X-coordinate.
		//
		// [in] inX - the X-coordinate
		//
		inline void		SetX(int32 inX) { m_X = inX; }
		
		//////////
		// Set the Y-coordinate.
		//
		// [in] inY - the Y-coordinate
		//
		inline void		SetY(int32 inY) { m_Y = inY; }

		//////////
		// Offset the X-coordinate.
		//
		// [in] inXOffset - offset for the X-coordinate
		//
		inline void		OffsetX(int32 inXOffset) { m_X += inXOffset; }
		
		//////////
		// Offset the Y-coordinate.
		//
		// [in] inYOffset - offset for the Y-coordinate
		//
		inline void		OffsetY(int32 inYOffset) { m_Y += inYOffset; }
		
		//////////
		// Get the X-coordinate
		//
		// [out] return - the X-coordinate
		//
		inline int32	X(void) const { return (m_X); }
		
		//////////
		// Get the Y-coordinate
		//
		// [out] return - the Y-coordinate
		//
		inline int32	Y(void) const { return (m_Y); }

		//////////
		// Set values for this point using another TPoint.  Same as Set().
		//
		// [in] inPt - TPoint to copy values from (r-value)
		// [out] return - l-value with coordinates set to r-value
		//
		TPoint			&operator=(const TPoint &inPt);
		
		//////////
		// Equality check.
		//
		// [in] inPt - a TPoint to check against for equality
		// [out] return - true if the two points are equal, false otherwise
		//
		bool			operator==(TPoint &inPt);

#if defined (_5L_QUICKTIME_)
		//////////
		// Get a Quicktime Point structure for the point.<br>
		// COMPILE FLAG - if defined _5L_QUICKTIME
		//
		// [out] return - a Quicktime Point structure for the point
		//
		Point			GetPoint(void);
		
		//////////
		// Set the point using the values from a Quicktime Point structure.<br>
		// COMPILE FLAG - if defined _5L_QUICKTIME
		//
		// [in] inPt - a Quicktime Point structure
		//
		void			Set(Point &inPt);
#endif
#if defined (_5L_WIN32_)
		
		//////////
		// Get a Win32 POINT structure for the point.<br>
		// COMPILE FLAG - if defined _5L_WIN32_
		//
		// [out] return - a Win32 POINT structure for the point
		//
		POINT			GetPOINT(void);
		
		//////////
		// Set the point using the values from a Win32 POINT structure.<br>
		// COMPILE FLAG - if defined _5L_WIN32_
		//
		// [in] inPt - a Win32 POINT structure
		//
		void			Set(POINT &inPt);
#endif

	protected:
        //////////
		// X-Coordinate
		//
		int32		m_X;
		
		//////////
		// Y-Coordinate
		//
		int32		m_Y;
};

END_NAMESPACE_FIVEL

#endif // _TPoint_h_

/*
 $Log$
 Revision 1.2  2002/03/04 15:16:10  hamon
 Added support for compiler's namespaces. Namespaces are only enabled on macintosh.

Moved OS specific configuration to TPlatform.h

Changes by Elizabeth and Eric, okayed by Eric.

 Revision 1.1  2001/09/24 15:11:00  tvw
 FiveL v3.00 Build 10

 First commit of /iml/FiveL/Release branch.

 There are now seperate branches for development and release
 codebases.

 Development - /iml/FiveL/Dev
 Release - /iml/FiveL/Release

 Revision 1.1  2000/04/06 17:06:10  chuck
 Initial check-in

*/
